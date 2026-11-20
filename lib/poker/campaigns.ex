defmodule Zoonk.Poker.Campaigns do
  @moduledoc "Persistent fictional-chip balances, match records, and Home-route progress."

  import Ecto.Query

  alias Zoonk.Poker.Campaign
  alias Zoonk.Poker.Match
  alias Zoonk.Poker.Opponents
  alias Zoonk.Repo

  @minimum_recovery_cash 100

  def get_or_create(user_id) do
    Repo.insert(Campaign.changeset(%Campaign{}, %{user_id: user_id}),
      on_conflict: :nothing,
      conflict_target: :user_id
    )

    Repo.get_by!(Campaign, user_id: user_id)
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

  def finish_match(user_id, match_id, result) when result in ["won", "lost", "tied"] do
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

      previous_win? =
        Repo.exists?(
          from(m in Match,
            where:
              m.user_id == ^user_id and m.opponent_id == ^match.opponent_id and
                m.status == "completed" and m.result == "won"
          )
        )

      payout =
        case result do
          "won" when match.opponent_id == "house-tournament" -> opponent.prize_pool
          "won" -> match.buy_in * 2
          "tied" -> match.buy_in
          "lost" -> 0
        end

      respect_reward = if result == "won" and opponent, do: opponent.respect_reward, else: 0
      respect_reward = if previous_win?, do: 0, else: respect_reward

      recovery_cash =
        if result == "won" and match.opponent_id == "teddy" and campaign.cash < @minimum_recovery_cash,
          do: @minimum_recovery_cash - campaign.cash,
          else: 0

      bracelet_at = if match.opponent_id == "house-tournament" and result == "won", do: DateTime.utc_now(), else: campaign.house_bracelet_earned_at

      campaign =
        campaign
        |> Campaign.changeset(%{
          cash: campaign.cash + payout + recovery_cash,
          respect: campaign.respect + respect_reward,
          house_bracelet_earned_at: bracelet_at
        })
        |> Repo.update!()

      match
      |> Match.changeset(%{
        status: "completed",
        result: result,
        payout: payout,
        completed_at: DateTime.utc_now()
      })
      |> Repo.update!()

      %{campaign: campaign, recovery_cash: recovery_cash}
    end)
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
end
