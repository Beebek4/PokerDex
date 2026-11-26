defmodule Zoonk.Poker.Bot.PlaystyleSimulation do
  @moduledoc "Builds a persisted baseline from full engine hands played by each bot policy."

  alias Zoonk.Poker.Bot.Observation
  alias Zoonk.Poker.Bot.Policy
  alias Zoonk.Poker.Native
  alias Zoonk.Poker.Opponents
  alias Zoonk.Poker.Playstyle

  @version 8
  @training_opponent %{id: "training-opponent", policy: :tight_aggressive, difficulty: "standard"}
  @table_size 6
  @metric_keys ~w(hands_seen vpip_hands pfr_hands three_bet_opportunities three_bets cbet_opportunities cbets postflop_actions aggressive_actions postflop_calls facing_bet_decisions calls_when_facing_bet folds_when_facing_bet saw_flop_hands showdowns)

  def version, do: @version

  def simulate_all(hands_per_bot \\ 1_000) when is_integer(hands_per_bot) and hands_per_bot > 0 do
    Map.new(Opponents.all(), fn opponent ->
      {opponent.id, simulate(opponent, hands_per_bot)}
    end)
  end

  def simulate(%{id: id} = opponent, hands) when is_integer(hands) and hands > 0 do
    seed = :erlang.phash2({id, @version}, 2_147_483_646) + 1
    random_state = :rand.seed_s(:exsss, {seed, seed + 1, seed + 2})

    initial = %{
      totals: empty_metrics(),
      hand: empty_hand(),
      random_state: random_state,
      target_index: 0,
      player_profiles: []
    }

    final =
      Enum.reduce(1..hands, initial, fn hand_number, state ->
        target_index = rem(hand_number - 1, @table_size)
        players = @training_opponent |> List.duplicate(@table_size) |> List.replace_at(target_index, opponent)
        dealer_idx = rem(hand_number + 2, @table_size)
        {session, view} = Native.start_tournament_hand(List.duplicate(100.0, @table_size), dealer_idx, 1.0, 2.0)
        state = %{state | hand: empty_hand(), target_index: target_index, player_profiles: players}
        play_hand(session, view, state, 0)
      end)

    metrics = final.totals
    vpip = percent(metrics["vpip_hands"], metrics["hands_seen"])
    aggression = Playstyle.aggression_score(metrics["aggressive_actions"], metrics["postflop_calls"])

    %{
      "simulation_version" => @version,
      "hands_simulated" => hands,
      "hands_seen" => metrics["hands_seen"],
      "vpip_percentage" => vpip,
      "pfr_percentage" => percent(metrics["pfr_hands"], metrics["hands_seen"]),
      "three_bet_percentage" => rate(metrics["three_bets"], metrics["three_bet_opportunities"]),
      "cbet_percentage" => rate(metrics["cbets"], metrics["cbet_opportunities"]),
      "aggression_factor" => aggression_factor(metrics["aggressive_actions"], metrics["postflop_calls"]),
      "wtsd_percentage" => rate(metrics["showdowns"], metrics["saw_flop_hands"]),
      "aggression_percentage" => aggression,
      "aggression_sample" => metrics["aggressive_actions"] + metrics["postflop_calls"],
      "graph_color" => Playstyle.graph_color(vpip, aggression),
      "call_percentage" => percent(metrics["calls_when_facing_bet"], metrics["facing_bet_decisions"]),
      "fold_to_bet_percentage" => percent(metrics["folds_when_facing_bet"], metrics["facing_bet_decisions"]),
      "showdown_percentage" => percent(metrics["showdowns"], metrics["hands_seen"]),
      "style_title" => Playstyle.style_title(vpip, aggression),
      "training_opponent" => "five tight-aggressive opponents at a six-player table"
    }
  end

  def profile(opponent_id) when is_binary(opponent_id) do
    case File.read(profile_path()) do
      {:ok, contents} ->
        with {:ok, document} <- Jason.decode(contents),
             @version <- document["simulation_version"] do
          get_in(document, ["bots", opponent_id])
        else
          _ -> nil
        end

      {:error, _reason} ->
        nil
    end
  end

  def save_profiles!(profiles, hands_per_bot) when is_map(profiles) do
    path = profile_path()
    File.mkdir_p!(Path.dirname(path))

    document = %{
      "simulation_version" => @version,
      "hands_per_bot" => hands_per_bot,
      "generated_at" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      "training_opponent" => "five tight-aggressive opponents at a six-player table",
      "bots" => profiles
    }

    File.write!(path, Jason.encode!(document, pretty: true) <> "\n")
    path
  end

  def profile_path do
    if Application.get_env(:zoonk, :app_env) in [:dev, :test] do
      Path.expand("priv/poker/bot_playstyle_profiles.json")
    else
      case :code.priv_dir(:zoonk) do
        {:error, _reason} -> Path.expand("priv/poker/bot_playstyle_profiles.json")
        priv_dir -> Path.join(List.to_string(priv_dir), "poker/bot_playstyle_profiles.json")
      end
    end
  end

  defp play_hand(_session, %{round: "Complete"} = view, state, _actions) do
    totals =
      Enum.reduce(@metric_keys, state.totals, fn key, acc ->
        Map.update!(acc, key, &(&1 + Map.get(state.hand, key, 0)))
      end)

    totals = Map.update!(totals, "hands_seen", &(&1 + 1))

    target_reached_showdown? =
      length(view.board) == 5 and Enum.count(view.player_folded, &(not &1)) > 1 and
        not Enum.at(view.player_folded, state.target_index, true)

    totals = if target_reached_showdown?, do: Map.update!(totals, "showdowns", &(&1 + 1)), else: totals
    %{state | totals: totals, hand: empty_hand()}
  end

  defp play_hand(_session, _view, _state, actions) when actions >= 100 do
    raise "Bot profile simulation exceeded 100 decisions in a hand"
  end

  defp play_hand(session, view, state, actions) do
    actor = view.acting_player
    profile = Enum.at(state.player_profiles, actor)
    {decision, random_state} = choose_decision(view, actor, profile, state.random_state)

    hand = state.hand |> maybe_mark_saw_flop(view) |> record_bot_action(view, actor, decision.action, state.target_index)

    next_view = Native.player_action(session, actor, decision.action, decision.amount)
    play_hand(session, next_view, %{state | hand: hand, random_state: random_state}, actions + 1)
  end

  defp choose_decision(view, actor, opponent, random_state) do
    {roll, random_state} = :rand.uniform_s(random_state)

    difficulty = opponent.difficulty
    observation = observation_for(view, actor)

    {Policy.choose(observation, opponent, difficulty, roll), random_state}
  end

  defp observation_for(view, actor) do
    hole_cards = if actor == 0, do: view.hero_cards, else: view.bot_private_cards
    actor_stack = Enum.at(view.player_stacks, actor, 0)

    opponent_stack =
      view.player_stacks
      |> Enum.with_index()
      |> Enum.reject(fn {_stack, index} -> index == actor end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.max(fn -> 0 end)

    %Observation{
      street: view.round,
      hole_cards: hole_cards,
      board: view.board,
      pot: view.pot,
      stack: actor_stack,
      opponent_stack: opponent_stack,
      to_call: view.to_call,
      min_raise: view.min_raise,
      max_raise: view.max_raise
    }
  end

  defp record_bot_action(hand, %{round: "Preflop"}, actor, action, target_index) do
    hand =
      if actor == target_index do
        hand =
          if hand["preflop_raise_seen"] and not hand["target_raised_preflop"] and
               not hand["three_bet_opportunity_recorded"] do
            hand
            |> Map.update!("three_bet_opportunities", &(&1 + 1))
            |> Map.update!("three_bets", &(&1 + if(action == "raise", do: 1, else: 0)))
            |> Map.put("three_bet_opportunity_recorded", true)
          else
            hand
          end

        hand
        |> Map.put("vpip_hands", if(action in ~w(call raise), do: 1, else: hand["vpip_hands"]))
        |> Map.put("pfr_hands", if(action == "raise", do: 1, else: hand["pfr_hands"]))
        |> Map.put("target_raised_preflop", hand["target_raised_preflop"] or action == "raise")
        |> Map.put("folded_preflop", action == "fold")
      else
        hand
      end

    if action == "raise" do
      hand
      |> Map.put("preflop_raise_seen", true)
      |> Map.put("preflop_last_raiser", actor)
    else
      hand
    end
  end

  defp record_bot_action(hand, view, actor, action, target_index) do
    if actor == target_index do
      hand
      |> Map.update!("postflop_actions", &(&1 + 1))
      |> Map.update!("aggressive_actions", &(&1 + if(action == "raise", do: 1, else: 0)))
      |> Map.update!("postflop_calls", &(&1 + if(action == "call", do: 1, else: 0)))
      |> maybe_count_facing_bet(view.to_call > 0, action)
      |> maybe_count_cbet(hand, view, action, target_index)
    else
      hand
    end
  end

  defp maybe_count_cbet(hand, original_hand, view, action, target_index) do
    if view.round == "Flop" and original_hand["preflop_last_raiser"] == target_index and
         not original_hand["cbet_decision_recorded"] do
      hand =
        if view.to_call == 0 do
          hand
          |> Map.update!("cbet_opportunities", &(&1 + 1))
          |> Map.update!("cbets", &(&1 + if(action == "raise", do: 1, else: 0)))
        else
          hand
        end

      Map.put(hand, "cbet_decision_recorded", true)
    else
      hand
    end
  end

  defp maybe_mark_saw_flop(hand, %{round: round}) when round in ["Flop", "Turn", "River"] do
    if hand["folded_preflop"], do: hand, else: Map.put(hand, "saw_flop_hands", 1)
  end

  defp maybe_mark_saw_flop(hand, _view), do: hand

  defp maybe_count_facing_bet(hand, true, action) do
    hand
    |> Map.update!("facing_bet_decisions", &(&1 + 1))
    |> Map.update!("calls_when_facing_bet", &(&1 + if(action == "call", do: 1, else: 0)))
    |> Map.update!("folds_when_facing_bet", &(&1 + if(action == "fold", do: 1, else: 0)))
  end

  defp maybe_count_facing_bet(hand, false, _action), do: hand

  defp aggression_factor(0, 0), do: nil
  defp aggression_factor(aggressive, 0) when aggressive > 0, do: "∞"
  defp aggression_factor(aggressive, calls), do: :erlang.float_to_binary(aggressive / calls, decimals: 1)

  defp percent(_numerator, denominator) when denominator <= 0, do: 0
  defp percent(numerator, denominator), do: round(numerator / denominator * 100)
  defp rate(_numerator, denominator) when denominator <= 0, do: nil
  defp rate(numerator, denominator), do: percent(numerator, denominator)

  defp empty_metrics, do: Map.new(@metric_keys, &{&1, 0})

  defp empty_hand do
    %{
      "vpip_hands" => 0,
      "pfr_hands" => 0,
      "three_bet_opportunities" => 0,
      "three_bets" => 0,
      "cbet_opportunities" => 0,
      "cbets" => 0,
      "postflop_actions" => 0,
      "aggressive_actions" => 0,
      "postflop_calls" => 0,
      "facing_bet_decisions" => 0,
      "calls_when_facing_bet" => 0,
      "folds_when_facing_bet" => 0,
      "saw_flop_hands" => 0,
      "preflop_raise_seen" => false,
      "preflop_last_raiser" => nil,
      "target_raised_preflop" => false,
      "three_bet_opportunity_recorded" => false,
      "folded_preflop" => false,
      "cbet_decision_recorded" => false
    }
  end
end
