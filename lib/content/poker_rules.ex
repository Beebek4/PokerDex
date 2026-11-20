defmodule Zoonk.Content.PokerRules do
  @moduledoc """
  Deterministic Hold’em mechanics for authored questions.

  This module evaluates cards and checks mechanical action legality. It does not assess strategy,
  opponent ranges, or whether one legal action is better than another.
  """

  @rank_values %{
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "T" => 10,
    "J" => 11,
    "Q" => 12,
    "K" => 13,
    "A" => 14
  }

  @rank_names %{
    0 => :high_card,
    1 => :one_pair,
    2 => :two_pair,
    3 => :three_of_a_kind,
    4 => :straight,
    5 => :flush,
    6 => :full_house,
    7 => :four_of_a_kind,
    8 => :straight_flush
  }

  @card_pattern ~r/\A(10|[2-9TJQKA])([cdhs])\z/i

  @type card :: %{rank: 2..14, suit: String.t(), code: String.t()}
  @type hand_result :: %{
          category: atom(),
          category_rank: 0..8,
          tiebreaker: [1..14],
          best_five: [String.t()]
        }

  @doc "Parses a stable card ID such as `As`, `Td`, or `10h`."
  @spec parse_card(term()) :: {:ok, card()} | {:error, String.t()}
  def parse_card(card_id) when is_binary(card_id) do
    case Regex.run(@card_pattern, String.trim(card_id)) do
      [_, rank_string, suit_string] ->
        rank_key = String.upcase(rank_string)
        rank = Map.fetch!(@rank_values, if(rank_key == "10", do: "T", else: rank_key))
        suit = String.downcase(suit_string)
        code = rank_code(rank) <> suit

        {:ok, %{rank: rank, suit: suit, code: code}}

      _ ->
        {:error, "invalid card ID: #{inspect(card_id)}"}
    end
  end

  def parse_card(card_id), do: {:error, "invalid card ID: #{inspect(card_id)}"}

  @doc "Checks that card IDs are valid and no physical card is repeated."
  @spec validate_cards(term()) :: :ok | {:error, String.t()}
  def validate_cards(cards) when is_list(cards) do
    with {:ok, parsed} <- parse_cards(cards),
         codes = Enum.map(parsed, & &1.code),
         true <- length(codes) == length(Enum.uniq(codes)) do
      :ok
    else
      false -> {:error, "duplicate card in deal"}
      {:error, _reason} = error -> error
    end
  end

  def validate_cards(_cards), do: {:error, "cards must be a list"}

  @doc "Evaluates the best five-card hand from five, six, or seven cards."
  @spec evaluate_hand(term()) :: {:ok, hand_result()} | {:error, String.t()}
  def evaluate_hand(cards) when is_list(cards) and length(cards) in 5..7 do
    with {:ok, parsed_cards} <- parse_cards(cards),
         :ok <- ensure_unique(parsed_cards) do
      parsed_cards
      |> combinations(5)
      |> Enum.map(&evaluate_five/1)
      |> Enum.reduce(&better_hand/2)
      |> then(&{:ok, &1})
    end
  end

  def evaluate_hand(cards) when is_list(cards), do: {:error, "a Hold’em hand needs five to seven cards"}
  def evaluate_hand(_cards), do: {:error, "cards must be a list"}

  @doc "Compares two five-to-seven-card hands."
  @spec compare_hands(term(), term()) :: {:ok, :first | :second | :tie} | {:error, String.t()}
  def compare_hands(first_cards, second_cards) do
    with {:ok, first} <- evaluate_hand(first_cards),
         {:ok, second} <- evaluate_hand(second_cards) do
      case compare_scores(first, second) do
        :gt -> {:ok, :first}
        :lt -> {:ok, :second}
        :eq -> {:ok, :tie}
      end
    end
  end

  @doc "Ranks players sharing a board and returns all tied winners."
  @spec rank_players([map()], [String.t()]) :: {:ok, map()} | {:error, String.t()}
  def rank_players(players, board) when is_list(players) and is_list(board) and length(players) >= 2 and length(board) in 3..5 do
    all_cards = Enum.flat_map(players, &player_hole_cards/1) ++ board

    with :ok <- validate_players(players),
         :ok <- validate_cards(all_cards),
         {:ok, rankings} <- evaluate_players(players, board) do
      best_score = rankings |> Enum.map(& &1.hand) |> Enum.max_by(&score_key/1) |> score_key()
      winners = for %{id: id, hand: hand} <- rankings, score_key(hand) == best_score, do: id

      {:ok, %{winners: winners, rankings: rankings}}
    end
  end

  def rank_players(_players, _board), do: {:error, "players and board must be provided"}

  @doc "Splits a pot evenly among distinct winners, preserving fractional learning units."
  @spec split_pot(number(), [term()]) :: {:ok, %{optional(term()) => number()}} | {:error, String.t()}
  def split_pot(pot, winners) when is_number(pot) and pot >= 0 and is_list(winners) and winners != [] do
    if Enum.all?(winners, &(not is_nil(&1))) and length(winners) == length(Enum.uniq(winners)) do
      share = pot / length(winners)
      {:ok, Map.new(winners, &{&1, share})}
    else
      {:error, "winners must be distinct non-nil IDs"}
    end
  end

  def split_pot(_pot, _winners), do: {:error, "pot must be non-negative and at least one winner is required"}

  @doc "Returns mechanically legal action names for the decision point."
  @spec legal_actions(number(), number()) :: {:ok, [String.t()]} | {:error, String.t()}
  def legal_actions(amount_to_call_bb, remaining_stack_bb)
      when is_number(amount_to_call_bb) and amount_to_call_bb >= 0 and is_number(remaining_stack_bb) and remaining_stack_bb >= 0 do
    actions =
      cond do
        remaining_stack_bb == 0 ->
          []

        amount_to_call_bb == 0 ->
          ["check", "bet"]

        true ->
          ["fold", "call"] ++ if(remaining_stack_bb > amount_to_call_bb, do: ["raise"], else: [])
      end

    {:ok, actions}
  end

  def legal_actions(_amount_to_call_bb, _remaining_stack_bb), do: {:error, "amount to call and remaining stack must be non-negative numbers"}

  @doc "Validates cards, remaining stack, and action choices in a scenario payload."
  @spec validate_scenario(map()) :: [String.t()]
  def validate_scenario(scenario) when is_map(scenario) do
    errors =
      scenario
      |> hero_and_board_cards()
      |> validate_cards_error()
      |> validate_remaining_stack(scenario)
      |> validate_pot_state(scenario)
      |> validate_question_mechanics(scenario)

    Enum.reverse(errors)
  end

  def validate_scenario(_scenario), do: ["scenario must be an object"]

  defp parse_cards(cards) do
    cards
    |> Enum.reduce_while({:ok, []}, fn card, {:ok, parsed} ->
      case parse_card(card) do
        {:ok, parsed_card} -> {:cont, {:ok, [parsed_card | parsed]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, parsed} -> {:ok, Enum.reverse(parsed)}
      error -> error
    end
  end

  defp ensure_unique(parsed_cards) do
    codes = Enum.map(parsed_cards, & &1.code)
    if length(codes) == length(Enum.uniq(codes)), do: :ok, else: {:error, "duplicate card in deal"}
  end

  defp evaluate_five(cards) do
    ranks = cards |> Enum.map(& &1.rank) |> Enum.sort(:desc)
    counts = Enum.frequencies(ranks)
    groups = counts |> Enum.map(fn {rank, count} -> {count, rank} end) |> Enum.sort(:desc)
    flush? = cards |> Enum.map(& &1.suit) |> Enum.uniq() |> length() == 1
    straight_high = straight_high(ranks)

    {category_rank, tiebreaker} =
      classify_five(groups, ranks, flush?, straight_high)

    %{
      category: Map.fetch!(@rank_names, category_rank),
      category_rank: category_rank,
      tiebreaker: tiebreaker,
      best_five: cards |> Enum.sort_by(&{-&1.rank, &1.suit}) |> Enum.map(& &1.code)
    }
  end

  defp classify_five(_groups, _ranks, true, high) when is_integer(high), do: {8, [high]}
  defp classify_five([{4, quad}, {1, kicker}], _ranks, _flush?, _straight), do: {7, [quad, kicker]}
  defp classify_five([{3, trips}, {2, pair}], _ranks, _flush?, _straight), do: {6, [trips, pair]}
  defp classify_five(_groups, ranks, true, _straight), do: {5, ranks}
  defp classify_five(_groups, _ranks, _flush?, high) when is_integer(high), do: {4, [high]}

  defp classify_five([{3, trips} | groups], _ranks, _flush?, _straight) do
    {3, [trips | group_ranks(groups)]}
  end

  defp classify_five([{2, high_pair}, {2, low_pair} | groups], _ranks, _flush?, _straight) do
    {2, [high_pair, low_pair | group_ranks(groups)]}
  end

  defp classify_five([{2, pair} | groups], _ranks, _flush?, _straight) do
    {1, [pair | group_ranks(groups)]}
  end

  defp classify_five(_groups, ranks, _flush?, _straight), do: {0, ranks}

  defp group_ranks(groups) do
    groups
    |> Enum.map(fn {_count, rank} -> rank end)
    |> Enum.sort(:desc)
  end

  defp straight_high(ranks) do
    unique = Enum.uniq(ranks)

    cond do
      unique == [14, 5, 4, 3, 2] -> 5
      length(unique) == 5 and hd(unique) - List.last(unique) == 4 -> hd(unique)
      true -> nil
    end
  end

  defp combinations(_cards, 0), do: [[]]
  defp combinations([], _count), do: []

  defp combinations([card | rest], count) do
    Enum.map(combinations(rest, count - 1), &[card | &1]) ++ combinations(rest, count)
  end

  defp better_hand(candidate, current) do
    if compare_scores(candidate, current) == :gt, do: candidate, else: current
  end

  defp compare_scores(first, second) do
    first_key = score_key(first)
    second_key = score_key(second)

    cond do
      first_key > second_key -> :gt
      first_key < second_key -> :lt
      true -> :eq
    end
  end

  defp score_key(%{category_rank: category, tiebreaker: tiebreaker}), do: {category, tiebreaker}

  defp evaluate_players(players, board) do
    players
    |> Enum.reduce_while({:ok, []}, fn player, {:ok, rankings} ->
      id = map_value(player, "id")
      hole_cards = map_value(player, "hole_cards")

      case evaluate_hand(hole_cards ++ board) do
        {:ok, hand} ->
          {:cont, {:ok, [%{id: id, hand: hand} | rankings]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, rankings} -> {:ok, Enum.reverse(rankings)}
      error -> error
    end
  end

  defp validate_players(players) do
    if Enum.all?(players, fn player ->
         is_map(player) and not is_nil(map_value(player, "id")) and is_list(map_value(player, "hole_cards")) and
           length(map_value(player, "hole_cards")) == 2
       end) do
      :ok
    else
      {:error, "each player needs an ID and exactly two hole cards"}
    end
  end

  defp player_hole_cards(player) when is_map(player) do
    case map_value(player, "hole_cards") do
      cards when is_list(cards) -> cards
      _ -> []
    end
  end

  defp player_hole_cards(_player), do: []

  defp hero_and_board_cards(scenario) do
    hero = map_value(scenario, "hero") || %{}
    (map_value(hero, "hole_cards") || []) ++ (map_value(scenario, "board") || [])
  end

  defp validate_cards_error(cards) do
    case validate_cards(cards) do
      :ok -> []
      {:error, reason} -> [reason]
    end
  end

  defp validate_remaining_stack(errors, scenario) do
    hero = map_value(scenario, "hero") || %{}
    starting_stack = map_value(hero, "starting_stack_bb")
    remaining_stack = map_value(hero, "remaining_stack_bb")

    cond do
      not is_number(remaining_stack) or remaining_stack < 0 -> ["hero.remaining_stack_bb must be non-negative" | errors]
      is_number(starting_stack) and remaining_stack > starting_stack -> ["hero.remaining_stack_bb cannot exceed hero.starting_stack_bb" | errors]
      true -> errors
    end
  end

  defp validate_question_mechanics(errors, scenario) do
    question = map_value(scenario, "question") || %{}

    case map_value(question, "type") do
      "choose_action" -> validate_action_state(errors, scenario)
      "hand_ranking" -> validate_hand_ranking_scenario(errors, scenario)
      _ -> errors
    end
  end

  defp validate_action_state(errors, scenario) do
    action_state = map_value(scenario, "action_state") || %{}
    amount_to_call = map_value(action_state, "amount_to_call_bb")
    street_bet = map_value(action_state, "street_bet_bb")
    hero_street_contribution = map_value(action_state, "hero_street_contribution_bb")
    hero = map_value(scenario, "hero") || %{}
    remaining_stack = map_value(hero, "remaining_stack_bb")
    provided_actions = map_value(scenario, "legal_actions") || []

    cond do
      not is_number(street_bet) or street_bet < 0 ->
        ["action_state.street_bet_bb must be non-negative" | errors]

      not is_number(hero_street_contribution) or hero_street_contribution < 0 or hero_street_contribution > street_bet ->
        ["action_state.hero_street_contribution_bb is inconsistent with the street bet" | errors]

      not nearly_equal?(amount_to_call, max(street_bet - hero_street_contribution, 0)) ->
        ["action_state.amount_to_call_bb does not match the street contributions" | errors]

      true ->
        case legal_actions(amount_to_call, remaining_stack) do
          {:ok, expected_actions} ->
            if Enum.sort(provided_actions) == Enum.sort(expected_actions) and length(provided_actions) == length(Enum.uniq(provided_actions)) do
              errors
            else
              ["legal_actions do not match the amount to call and remaining stack" | errors]
            end

          {:error, reason} ->
            ["action_state is invalid: #{reason}" | errors]
        end
    end
  end

  defp validate_pot_state(errors, scenario) do
    question = map_value(scenario, "question") || %{}

    if map_value(question, "type") == "choose_action" do
      action_state = map_value(scenario, "action_state") || %{}
      table = map_value(scenario, "table") || %{}
      hero = map_value(scenario, "hero") || %{}
      contributions = map_value(action_state, "contributions_by_seat_bb")
      seat_count = map_value(table, "seat_count")
      hero_seat = map_value(hero, "seat")
      pot = map_value(scenario, "pot")
      starting_stack = map_value(hero, "starting_stack_bb")
      remaining_stack = map_value(hero, "remaining_stack_bb")

      errors =
        if is_list(contributions) and is_integer(seat_count) and length(contributions) == seat_count and
             Enum.all?(contributions, &(is_number(&1) and &1 >= 0)) do
          contribution_sum = Enum.sum(contributions)

          if nearly_equal?(pot, contribution_sum) do
            errors
          else
            ["pot does not equal the sum of contributions_by_seat_bb" | errors]
          end
        else
          ["action_state.contributions_by_seat_bb must have one non-negative amount per seat" | errors]
        end

      hero_contribution = if is_list(contributions) and is_integer(hero_seat), do: Enum.at(contributions, hero_seat - 1)

      if is_number(hero_contribution) and is_number(remaining_stack) and is_number(starting_stack) and
           nearly_equal?(hero_contribution + remaining_stack, starting_stack) do
        errors
      else
        ["hero remaining stack and committed contribution do not equal the effective stack" | errors]
      end
    else
      errors
    end
  end

  defp nearly_equal?(left, right) when is_number(left) and is_number(right), do: abs(left - right) <= 0.000001
  defp nearly_equal?(_left, _right), do: false

  defp validate_hand_ranking_scenario(errors, scenario) do
    hero = map_value(scenario, "hero") || %{}
    cards = (map_value(hero, "hole_cards") || []) ++ (map_value(scenario, "board") || [])

    case evaluate_hand(cards) do
      {:ok, _hand} -> errors
      {:error, reason} -> ["hand_ranking scenario is invalid: #{reason}" | errors]
    end
  end

  defp map_value(map, key) when is_map(map) do
    Map.get(map, key, Map.get(map, String.to_atom(key)))
  end

  defp map_value(_map, _key), do: nil

  defp rank_code(rank) do
    case Enum.find(@rank_values, fn {_code, value} -> value == rank end) do
      {"10", _rank} -> "T"
      {code, _rank} -> code
    end
  end
end
