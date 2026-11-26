defmodule Zoonk.Poker.Stats do
  @moduledoc "Aggregates match actions in memory and persists compact playstyle totals."

  import Ecto.Query

  alias Zoonk.Poker.MatchStats
  alias Zoonk.Poker.OpponentStats
  alias Zoonk.Poker.PlayerStats
  alias Zoonk.Poker.Playstyle
  alias Zoonk.Repo

  @counter_keys ~w(hands_seen vpip_hands pfr_hands three_bet_opportunities three_bets cbet_opportunities cbets postflop_actions aggressive_actions postflop_calls facing_bet_decisions calls_when_facing_bet folds_when_facing_bet saw_flop_hands showdowns wtsd_showdowns)a

  def new_match(mode) when mode in [:heads_up, :tournament], do: %{mode: Atom.to_string(mode), hands_played: 0, players: %{}}

  @doc "Adds one completed hand to the match accumulator without writing to the database."
  def record_hand(summary, actions, participants, board, player_folded) do
    players =
      Enum.reduce(participants, summary.players, fn %{index: index, id: id}, acc ->
        metrics =
          hand_metrics(
            actions,
            index,
            length(board) == 5 and Enum.count(player_folded, &(not &1)) > 1 and
              not Enum.at(player_folded, index, false),
            length(board) >= 3
          )

        acc
        |> Map.get(id, empty_metrics())
        |> add_metrics(metrics)
        |> then(&Map.put(acc, id, &1))
      end)

    %{summary | hands_played: summary.hands_played + 1, players: players}
  end

  @doc "Persists a compact match snapshot and atomically increments player and opponent rollups."
  def persist_match!(match, user_id, summary) do
    mode = summary.mode
    players = summary.players

    Repo.insert!(
      MatchStats.changeset(%MatchStats{}, %{
        match_id: match.id,
        user_id: user_id,
        mode: mode,
        hands_played: summary.hands_played,
        metrics: players
      })
    )

    upsert_rollup!(PlayerStats, %{user_id: user_id, mode: mode}, Map.get(players, "hero", empty_metrics()))

    players
    |> Enum.reject(fn {id, _metrics} -> id == "hero" end)
    |> Enum.each(fn {opponent_id, metrics} ->
      upsert_rollup!(OpponentStats, %{user_id: user_id, opponent_id: opponent_id, mode: mode}, metrics)
    end)

    :ok
  end

  def get_player_profile(user_id) do
    metrics = user_id |> rows(PlayerStats) |> sum_rows()
    hands = metrics["hands_seen"]
    looseness = percent(metrics["vpip_hands"], hands)
    aggression = aggression_score(metrics["aggressive_actions"], metrics["postflop_calls"])

    Map.merge(
      %{
        hands_seen: hands,
        sample_label: player_sample_label(hands),
        title: if(hands == 0, do: "Unrated", else: Playstyle.style_title(looseness, aggression)),
        looseness_percentage: looseness,
        aggression_percentage: aggression,
        chart_position: chart_position(hands, looseness, aggression),
        graph_color: if(hands == 0, do: "#8797AF", else: Playstyle.graph_color(looseness, aggression))
      },
      poker_rates(metrics)
    )
  end

  def get_opponent_profile(user_id, opponent_id) do
    metrics =
      from(s in OpponentStats,
        where: s.user_id == ^user_id and s.opponent_id == ^opponent_id
      )
      |> Repo.all()
      |> sum_rows()

    hands = metrics["hands_seen"]

    Map.merge(
      %{
        hands_seen: hands,
        sample_label: sample_label(hands),
        vpip_percentage: percent(metrics["vpip_hands"], hands),
        pfr_percentage: percent(metrics["pfr_hands"], hands),
        aggression_percentage: aggression_score(metrics["aggressive_actions"], metrics["postflop_calls"]),
        call_percentage: percent(metrics["calls_when_facing_bet"], metrics["facing_bet_decisions"]),
        showdown_percentage: percent(metrics["showdowns"], hands),
        exploit_tip: exploit_tip(metrics, hands)
      },
      poker_rates(metrics)
    )
  end

  defp hand_metrics(actions, player_index, showdown?, board_reached_flop?) do
    own_actions = Enum.filter(actions, &(&1.actor_index == player_index))
    preflop_all = Enum.filter(actions, &(&1.street == "Preflop"))
    preflop = Enum.filter(own_actions, &(&1.street == "Preflop"))
    postflop = Enum.reject(own_actions, &(&1.street == "Preflop"))
    flop = Enum.filter(actions, &(&1.street == "Flop"))
    {three_bet_opportunity?, three_bet?} = three_bet_result(preflop_all, player_index)

    preflop_raiser? =
      preflop_all
      |> Enum.filter(&(&1.action == "raise"))
      |> List.last()
      |> case do
        nil -> false
        action -> action.actor_index == player_index
      end

    first_flop_action = Enum.find(flop, &(&1.actor_index == player_index))
    cbet_opportunity? = preflop_raiser? and not is_nil(first_flop_action) and not first_flop_action.facing_bet?
    cbet? = cbet_opportunity? and first_flop_action.action == "raise"
    saw_flop? = board_reached_flop? and not Enum.any?(preflop, &(&1.action == "fold"))

    %{
      "hands_seen" => 1,
      "vpip_hands" => bool_count(Enum.any?(preflop, &(&1.action in ["call", "raise"]))),
      "pfr_hands" => bool_count(Enum.any?(preflop, &(&1.action == "raise"))),
      "three_bet_opportunities" => bool_count(three_bet_opportunity?),
      "three_bets" => bool_count(three_bet?),
      "cbet_opportunities" => bool_count(cbet_opportunity?),
      "cbets" => bool_count(cbet?),
      "saw_flop_hands" => bool_count(saw_flop?),
      "postflop_actions" => Enum.count(postflop, &(&1.action in ~w(check call raise fold))),
      "aggressive_actions" => Enum.count(postflop, &(&1.action == "raise")),
      "postflop_calls" => Enum.count(postflop, &(&1.action == "call")),
      "facing_bet_decisions" => Enum.count(postflop, &(&1.facing_bet? and &1.action in ~w(call raise fold))),
      "calls_when_facing_bet" => Enum.count(postflop, &(&1.facing_bet? and &1.action == "call")),
      "folds_when_facing_bet" => Enum.count(postflop, &(&1.facing_bet? and &1.action == "fold")),
      "showdowns" => bool_count(showdown?),
      "wtsd_showdowns" => bool_count(showdown?)
    }
  end

  defp three_bet_result(actions, player_index) do
    actions
    |> Enum.reduce_while({false, false, false, false}, fn action, {raise_seen?, player_raised?, opportunity?, three_bet?} ->
      if action.actor_index == player_index and raise_seen? and not player_raised? and not opportunity? do
        {:halt, {raise_seen?, player_raised?, true, action.action == "raise"}}
      else
        next_player_raised? = player_raised? or (action.actor_index == player_index and action.action == "raise")
        next_raise_seen? = raise_seen? or (action.actor_index != player_index and action.action == "raise")
        {:cont, {next_raise_seen?, next_player_raised?, opportunity?, three_bet?}}
      end
    end)
    |> then(fn {_raise_seen?, _player_raised?, opportunity?, three_bet?} -> {opportunity?, three_bet?} end)
  end

  defp poker_rates(metrics) do
    %{
      vpip_percentage: percent(metrics["vpip_hands"], metrics["hands_seen"]),
      pfr_percentage: percent(metrics["pfr_hands"], metrics["hands_seen"]),
      three_bet_percentage: rate(metrics["three_bets"], metrics["three_bet_opportunities"]),
      cbet_percentage: rate(metrics["cbets"], metrics["cbet_opportunities"]),
      aggression_factor: aggression_factor(metrics["aggressive_actions"], metrics["postflop_calls"]),
      wtsd_percentage: rate(metrics["wtsd_showdowns"], metrics["saw_flop_hands"])
    }
  end

  defp aggression_factor(0, 0), do: nil
  defp aggression_factor(aggressive, 0) when aggressive > 0, do: "∞"
  defp aggression_factor(aggressive, calls), do: :erlang.float_to_binary(aggressive / calls, decimals: 1)

  defp aggression_score(aggressive, calls), do: Playstyle.aggression_score(aggressive, calls)

  defp rate(_numerator, 0), do: nil
  defp rate(numerator, denominator), do: percent(numerator, denominator)

  defp upsert_rollup!(schema, keys, metrics) do
    now = DateTime.truncate(DateTime.utc_now(), :microsecond)
    increments = Enum.map(@counter_keys, &{&1, Map.get(metrics, Atom.to_string(&1), 0)})
    attrs = Map.merge(keys, Map.new(increments))

    Repo.insert!(schema.changeset(struct(schema), attrs),
      on_conflict: [inc: increments, set: [updated_at: now]],
      conflict_target: Map.keys(keys)
    )
  end

  defp rows(user_id, schema), do: Repo.all(from s in schema, where: s.user_id == ^user_id)

  defp sum_rows(rows) do
    Enum.reduce(rows, empty_metrics(), fn row, totals ->
      Enum.reduce(@counter_keys, totals, fn key, acc ->
        Map.update!(acc, Atom.to_string(key), &(&1 + Map.fetch!(row, key)))
      end)
    end)
  end

  defp add_metrics(left, right),
    do:
      Map.new(@counter_keys, fn key ->
        name = Atom.to_string(key)
        {name, left[name] + right[name]}
      end)

  defp chart_position(0, _looseness, _aggression), do: %{x: 120, y: 100}

  defp chart_position(_hands, looseness, aggression) do
    %{x: Float.round(55 + 1.3 * looseness, 1), y: Float.round(165 - 1.3 * aggression, 1)}
  end

  defp player_sample_label(0), do: "No hands yet"
  defp player_sample_label(hands), do: sample_label(hands)

  defp exploit_tip(_metrics, hands) when hands < 12, do: "Play more hands to build a reliable read on this opponent."

  defp exploit_tip(metrics, hands) do
    vpip = percent(metrics["vpip_hands"], hands)
    calls = percent(metrics["calls_when_facing_bet"], metrics["facing_bet_decisions"])
    pfr = percent(metrics["pfr_hands"], hands)
    aggression = percent(metrics["aggressive_actions"], metrics["postflop_actions"])

    cond do
      vpip >= 40 and calls >= 45 -> "Plays many hands and calls often: value-bet strong hands and bluff less."
      vpip <= 22 and pfr <= 18 -> "Plays selectively: apply pressure when they show weakness and respect strong raises."
      aggression >= 45 -> "Often raises after the flop: continue with solid bluff-catchers."
      true -> "Compare their preflop choices with their postflop actions."
    end
  end

  defp sample_label(hands) when hands < 12, do: "Early read"
  defp sample_label(hands) when hands < 40, do: "Taking shape"
  defp sample_label(_hands), do: "Established sample"
  defp percent(_numerator, denominator) when denominator <= 0, do: 0
  defp percent(numerator, denominator), do: round(numerator / denominator * 100)
  defp bool_count(true), do: 1
  defp bool_count(false), do: 0
  defp empty_metrics, do: Map.new(@counter_keys, &{Atom.to_string(&1), 0})
end
