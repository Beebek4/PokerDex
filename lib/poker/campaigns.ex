defmodule Zoonk.Poker.Campaigns do
  @moduledoc "Persistent fictional-chip balances, match records, and Home-route progress."

  import Ecto.Query

  alias Zoonk.Poker.Campaign
  alias Zoonk.Poker.Match
  alias Zoonk.Poker.Opponents
  alias Zoonk.Poker.Stats
  alias Zoonk.Repo
  alias Zoonk.Retention

  require Logger

  @starting_cash 100
  @minimum_recovery_cash 100

  def get_or_create(user_id) do
    Repo.insert(Campaign.changeset(%Campaign{}, %{user_id: user_id, cash: @starting_cash}),
      on_conflict: :nothing,
      conflict_target: :user_id
    )

    user_id
    |> then(&Repo.get_by!(Campaign, user_id: &1))
    |> reconcile_respect_streak()
  end

  @doc "Returns the user's active match, if one needs to be explicitly abandoned."
  def get_active_match(user_id) do
    Repo.one(
      from(m in Match,
        where: m.user_id == ^user_id and m.status == "active",
        order_by: [desc: m.inserted_at],
        limit: 1
      )
    )
  end

  @doc "Awards the once-per-day chip reward and updates the user's consecutive-day streak atomically."
  def claim_daily_reward(user_id, today \\ Date.utc_today()) do
    get_or_create(user_id)

    Repo.transaction(fn ->
      campaign = Repo.one!(from(c in Campaign, where: c.user_id == ^user_id, lock: "FOR UPDATE"))

      if campaign.last_daily_reward_on == today do
        reward = daily_reward(campaign.day_streak)

        %{
          awarded?: false,
          reward: reward,
          chips: campaign.cash,
          day_streak: campaign.day_streak,
          claim_date: today
        }
      else
        day_streak = next_day_streak(campaign, today)
        reward = daily_reward(day_streak)

        campaign =
          campaign
          |> Campaign.changeset(%{
            cash: campaign.cash + reward,
            day_streak: day_streak,
            last_daily_reward_on: today
          })
          |> Repo.update!()

        %{
          awarded?: true,
          reward: reward,
          chips: campaign.cash,
          day_streak: campaign.day_streak,
          claim_date: today
        }
      end
    end)
  end

  @doc "Refunds active matches after a disconnected LiveView, whose native hand state is transient."
  def abandon_active_matches(user_id) do
    get_or_create(user_id)

    Repo.transaction(fn ->
      campaign = Repo.one!(from(c in Campaign, where: c.user_id == ^user_id, lock: "FOR UPDATE"))
      matches = Repo.all(from(m in Match, where: m.user_id == ^user_id and m.status == "active", lock: "FOR UPDATE"))

      refund = Enum.sum(Enum.map(matches, & &1.buy_in))

      Enum.each(matches, fn match ->
        match
        |> Match.changeset(%{status: "abandoned", payout: match.buy_in, completed_at: DateTime.utc_now()})
        |> Repo.update!()
      end)

      if refund > 0 do
        campaign
        |> Campaign.changeset(%{cash: campaign.cash + refund})
        |> Repo.update!()
      end

      %{campaign | cash: campaign.cash + refund}
    end)
  end

  def start_match(user_id, opponent, difficulty) do
    get_or_create(user_id)

    Repo.transaction(fn ->
      campaign = Repo.one!(from(c in Campaign, where: c.user_id == ^user_id, lock: "FOR UPDATE"))

      if Repo.exists?(from(m in Match, where: m.user_id == ^user_id and m.status == "active")) do
        Repo.rollback(:match_already_active)
      end

      cond do
        campaign.respect < opponent.respect_required ->
          Repo.rollback(:respect_locked)

        campaign.cash < opponent.buy_in ->
          Repo.rollback(:insufficient_cash)

        true ->
          next_campaign =
            campaign
            |> Campaign.changeset(%{cash: campaign.cash - opponent.buy_in})
            |> Repo.update!()

          match =
            %Match{}
            |> Match.changeset(%{
              user_id: user_id,
              opponent_id: opponent.id,
              difficulty: difficulty,
              status: "active",
              buy_in: opponent.buy_in,
              payout: 0,
              started_at: DateTime.utc_now()
            })
            |> Repo.insert!()

          {next_campaign, match}
      end
    end)
  end

  def finish_match(user_id, match_id, result, stats_summary \\ nil) when result in ["won", "lost", "tied"] do
    transaction_result =
      Repo.transaction(fn ->
        match =
          Repo.one!(
            from(m in Match,
              where: m.id == ^match_id and m.user_id == ^user_id,
              lock: "FOR UPDATE"
            )
          )

        unless match.status == "active" do
          Repo.rollback(:already_finished)
        end

        campaign = Repo.one!(from(c in Campaign, where: c.user_id == ^user_id, lock: "FOR UPDATE"))
        opponent = Opponents.get(match.opponent_id)

        payout =
          case result do
            "won" when match.opponent_id == "house-tournament" -> opponent.prize_pool
            "won" -> match.buy_in * 2
            "tied" -> match.buy_in
            "lost" -> 0
          end

        respect = respect_after_result(campaign.respect, opponent, result)
        respect_earned = respect - campaign.respect

        recovery_cash =
          if result == "won" and match.opponent_id == "teddy" and campaign.cash < @minimum_recovery_cash,
            do: @minimum_recovery_cash - campaign.cash,
            else: 0

        bracelet_at = if match.opponent_id == "house-tournament" and result == "won", do: DateTime.utc_now(), else: campaign.house_bracelet_earned_at

        campaign =
          campaign
          |> Campaign.changeset(%{
            cash: campaign.cash + payout + recovery_cash,
            respect: respect,
            house_bracelet_earned_at: bracelet_at
          })
          |> Repo.update!()

        match =
          match
          |> Match.changeset(%{
            status: "completed",
            result: result,
            payout: payout,
            completed_at: DateTime.utc_now()
          })
          |> Repo.update!()

        %{
          match: match,
          campaign: campaign,
          recovery_cash: recovery_cash,
          chips_earned: payout + recovery_cash,
          respect_earned: respect_earned
        }
      end)

    case transaction_result do
      {:ok, %{match: match} = finished_match} ->
        if stats_summary, do: persist_match_study_data(match, user_id, stats_summary, result)
        {:ok, Map.delete(finished_match, :match)}

      error ->
        error
    end
  end

  defp persist_match_study_data(match, user_id, summary, result) do
    case Repo.transaction(fn -> Stats.persist_match!(match, user_id, summary) end) do
      {:ok, _result} -> :ok
      {:error, reason} -> Logger.warning("Poker match stats were not saved: #{inspect(reason)}")
    end

    try do
      Retention.track_match_completion(user_id, match.id, summary, result)
    rescue
      error -> Logger.warning("Poker match completion event was not saved: #{Exception.message(error)}")
    catch
      kind, reason -> Logger.warning("Poker match completion event was not saved: #{inspect({kind, reason})}")
    end
  end

  def get_progress(user_id) do
    completed =
      Repo.all(
        from(m in Match,
          where: m.user_id == ^user_id and m.status == "completed",
          select: m.result
        )
      )

    games_played = length(completed)
    wins = Enum.count(completed, &(&1 == "won"))

    %{
      total: %{
        games_played: games_played,
        win_percentage: if(games_played == 0, do: nil, else: round(wins / games_played * 100))
      }
    }
  end

  defp reconcile_respect_streak(campaign) do
    completed_matches =
      Repo.all(
        from(m in Match,
          where: m.user_id == ^campaign.user_id and m.status == "completed",
          order_by: [asc: m.inserted_at, asc: m.id],
          select: {m.opponent_id, m.result}
        )
      )

    if completed_matches == [] do
      campaign
    else
      respect = completed_matches |> Enum.reduce(0, &advance_respect_streak/2) |> max(campaign.respect)

      if respect == campaign.respect do
        campaign
      else
        campaign
        |> Campaign.changeset(%{respect: respect})
        |> Repo.update!()
      end
    end
  end

  defp next_day_streak(%{last_daily_reward_on: last_reward_on, day_streak: day_streak}, today) when not is_nil(last_reward_on) do
    if Date.diff(today, last_reward_on) == 1, do: day_streak + 1, else: 1
  end

  defp next_day_streak(_campaign, _today), do: 1

  defp daily_reward(day_streak), do: 100 * (day_streak + 1)

  defp advance_respect_streak({_opponent_id, result}, respect) when result in ["lost", "tied"], do: respect

  defp advance_respect_streak({opponent_id, "won"}, respect) do
    case Opponents.get(opponent_id) do
      %{respect_required: required, respect_reward: reward} when required == respect -> respect + reward
      _opponent -> respect
    end
  end

  defp advance_respect_streak(_match, respect), do: respect

  defp respect_after_result(respect, %{id: "house-tournament", respect_required: required, respect_reward: reward}, "won") when required == respect, do: respect + reward

  defp respect_after_result(respect, %{id: "house-tournament"}, _result), do: respect
  defp respect_after_result(respect, _opponent, result) when result in ["lost", "tied"], do: respect

  defp respect_after_result(respect, %{respect_required: required, respect_reward: reward}, "won") when required == respect, do: respect + reward

  defp respect_after_result(respect, _opponent, "won"), do: respect
end
