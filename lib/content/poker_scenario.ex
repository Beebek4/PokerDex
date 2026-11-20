defmodule Zoonk.Content.PokerScenario do
  @moduledoc """
  Validation helpers for structured Hold’em scenario payloads stored on lesson steps.

  This module checks the scenario content shape. Deterministic card and action-state checks live in
  `Zoonk.Content.PokerRules`; strategy scoring remains authored content.
  """

  @required_fields ~w(scenario_id version status format table hero effective_stack_bb blinds street board pot action_history legal_actions question assumptions skill_tags)
  @statuses ~w(draft reviewed published)
  @streets ~w(preflop flop turn river)
  @question_types ~w(choose_action hand_ranking)

  @type payload :: map()

  @spec validate(payload()) :: [String.t()]
  def validate(payload) when is_map(payload) do
    errors =
      @required_fields
      |> Enum.reduce([], fn field, errors ->
        if is_nil(value(payload, field)), do: ["#{field} is required" | errors], else: errors
      end)
      |> validate_scenario_id(payload)
      |> validate_version(payload)
      |> validate_status(payload)
      |> validate_format(payload)
      |> validate_street(payload)
      |> validate_container(payload, "table", :map)
      |> validate_container(payload, "hero", :map)
      |> validate_container(payload, "blinds", :map)
      |> validate_container(payload, "board", :list)
      |> validate_container(payload, "action_history", :list)
      |> validate_container(payload, "legal_actions", :list)
      |> validate_container(payload, "assumptions", :list)
      |> validate_container(payload, "skill_tags", :non_empty_list)
      |> validate_table(payload)
      |> validate_hero(payload)
      |> validate_effective_stack(payload)
      |> validate_blinds(payload)
      |> validate_pot(payload)
      |> validate_board(payload)
      |> validate_legal_actions(payload)
      |> validate_skill_tags(payload)
      |> validate_question(payload)
      |> validate_action_state(payload)
      |> validate_review(payload)

    Enum.reverse(errors)
  end

  def validate(_payload), do: ["must be an object"]

  @spec version(payload()) :: pos_integer() | nil
  def version(payload) when is_map(payload) do
    case value(payload, "version") do
      version when is_integer(version) and version > 0 -> version
      _ -> nil
    end
  end

  def version(_payload), do: nil

  defp validate_scenario_id(errors, payload) do
    case value(payload, "scenario_id") do
      value when is_binary(value) and value != "" -> errors
      _ -> ["scenario_id must be a non-empty string" | errors]
    end
  end

  defp validate_version(errors, payload) do
    case value(payload, "version") do
      value when is_integer(value) and value > 0 -> errors
      _ -> ["version must be a positive integer" | errors]
    end
  end

  defp validate_status(errors, payload) do
    case value(payload, "status") do
      status when status in @statuses -> errors
      _ -> ["status must be draft, reviewed, or published" | errors]
    end
  end

  defp validate_format(errors, payload) do
    case value(payload, "format") do
      "six_max_cash" -> errors
      _ -> ["format must be six_max_cash for the MVP" | errors]
    end
  end

  defp validate_street(errors, payload) do
    case value(payload, "street") do
      street when street in @streets -> errors
      _ -> ["street must be preflop, flop, turn, or river" | errors]
    end
  end

  defp validate_container(errors, payload, field, expected) do
    value = value(payload, field)

    valid? =
      case expected do
        :map -> is_map(value)
        :list -> is_list(value)
        :non_empty_list -> is_list(value) and value != []
      end

    if valid?, do: errors, else: ["#{field} has an invalid shape" | errors]
  end

  defp validate_table(errors, payload) do
    table = value(payload, "table")

    if is_map(table) do
      errors
      |> validate_required_map_fields(table, "table", ~w(seat_count button_seat players_in_hand))
      |> validate_integer_range(value(table, "seat_count"), 2, 6, "table.seat_count must be between 2 and 6")
      |> validate_players_in_hand(value(table, "players_in_hand"), value(table, "seat_count"))
      |> validate_button_seat(value(table, "button_seat"), value(table, "seat_count"))
    else
      errors
    end
  end

  defp validate_hero(errors, payload) do
    hero = value(payload, "hero")

    if is_map(hero) do
      errors = validate_required_map_fields(errors, hero, "hero", ~w(seat position starting_stack_bb remaining_stack_bb hole_cards))
      errors = validate_non_empty_string(errors, value(hero, "position"), "hero.position must be a non-empty string")
      errors = validate_positive_number(errors, value(hero, "starting_stack_bb"), "hero.starting_stack_bb must be greater than zero")
      errors = validate_remaining_stack(errors, value(hero, "starting_stack_bb"), value(hero, "remaining_stack_bb"))

      seat_count = payload |> value("table") |> map_value("seat_count")
      seat_max = if is_integer(seat_count), do: seat_count, else: 6
      errors = validate_integer_range(errors, value(hero, "seat"), 1, seat_max, "hero.seat must be within the table seat count")

      case value(hero, "hole_cards") do
        cards when is_list(cards) and length(cards) == 2 -> errors
        _ -> ["hero.hole_cards must contain two cards" | errors]
      end
    else
      errors
    end
  end

  defp validate_effective_stack(errors, payload) do
    effective_stack = value(payload, "effective_stack_bb")
    hero = value(payload, "hero") || %{}
    starting_stack = value(hero, "starting_stack_bb")

    cond do
      not is_number(effective_stack) or effective_stack <= 0 -> ["effective_stack_bb must be greater than zero" | errors]
      is_number(starting_stack) and effective_stack > starting_stack -> ["effective_stack_bb cannot exceed hero.starting_stack_bb" | errors]
      true -> errors
    end
  end

  defp validate_blinds(errors, payload) do
    blinds = value(payload, "blinds")

    if is_map(blinds) do
      errors = validate_required_map_fields(errors, blinds, "blinds", ~w(small_blind big_blind ante straddle))
      errors = validate_positive_number(errors, value(blinds, "small_blind"), "blinds.small_blind must be greater than zero")
      errors = validate_positive_number(errors, value(blinds, "big_blind"), "blinds.big_blind must be greater than zero")
      errors = validate_non_negative_number(errors, value(blinds, "ante"), "blinds.ante cannot be negative")
      errors = validate_non_negative_number(errors, value(blinds, "straddle"), "blinds.straddle cannot be negative")

      if is_number(value(blinds, "small_blind")) and is_number(value(blinds, "big_blind")) and
           value(blinds, "big_blind") >= value(blinds, "small_blind") do
        errors
      else
        ["blinds.big_blind must be at least blinds.small_blind" | errors]
      end
    else
      errors
    end
  end

  defp validate_pot(errors, payload) do
    validate_non_negative_number(errors, value(payload, "pot"), "pot cannot be negative")
  end

  defp validate_board(errors, payload) do
    street = value(payload, "street")
    board = value(payload, "board")
    expected_count = %{"preflop" => 0, "flop" => 3, "turn" => 4, "river" => 5}[street]

    if is_list(board) and is_integer(expected_count) and length(board) == expected_count do
      errors
    else
      ["board card count must match the street" | errors]
    end
  end

  defp validate_legal_actions(errors, payload) do
    legal_actions = value(payload, "legal_actions")
    supported_actions = ~w(fold check call bet raise)

    question = value(payload, "question") || %{}
    question_type = value(question, "type")

    valid_shape? = is_list(legal_actions) and Enum.all?(legal_actions, &(&1 in supported_actions))
    valid_question_actions? = question_type == "hand_ranking" or legal_actions != []

    if valid_shape? and valid_question_actions? do
      errors
    else
      ["legal_actions must contain supported actions and be non-empty for action questions" | errors]
    end
  end

  defp validate_skill_tags(errors, payload) do
    skill_tags = value(payload, "skill_tags")

    if is_list(skill_tags) and skill_tags != [] and Enum.all?(skill_tags, &(is_binary(&1) and &1 != "")) do
      errors
    else
      ["skill_tags must contain non-empty identifiers" | errors]
    end
  end

  defp validate_required_map_fields(errors, map, prefix, fields) do
    Enum.reduce(fields, errors, fn field, errors ->
      if is_nil(value(map, field)), do: ["#{prefix}.#{field} is required" | errors], else: errors
    end)
  end

  defp validate_integer_range(errors, value, minimum, maximum, message) do
    if is_integer(value) and value >= minimum and value <= maximum, do: errors, else: [message | errors]
  end

  defp validate_players_in_hand(errors, players, seats) do
    if is_integer(players) and is_integer(seats) and players >= 2 and players <= seats do
      errors
    else
      ["table.players_in_hand must be between two and table.seat_count" | errors]
    end
  end

  defp validate_button_seat(errors, button, seats) do
    if is_integer(button) and is_integer(seats) and button >= 1 and button <= seats do
      errors
    else
      ["table.button_seat must be within the table seat count" | errors]
    end
  end

  defp validate_positive_number(errors, value, message) do
    if is_number(value) and value > 0, do: errors, else: [message | errors]
  end

  defp validate_non_negative_number(errors, value, message) do
    if is_number(value) and value >= 0, do: errors, else: [message | errors]
  end

  defp validate_non_empty_string(errors, value, message) do
    if is_binary(value) and String.trim(value) != "", do: errors, else: [message | errors]
  end

  defp validate_question(errors, payload) do
    question = value(payload, "question")

    if is_map(question) do
      type = value(question, "type")
      prompt = value(question, "prompt")

      errors =
        if type in @question_types, do: errors, else: ["question.type is not supported" | errors]

      if is_binary(prompt) and prompt != "" do
        errors
      else
        ["question.prompt must be a non-empty string" | errors]
      end
    else
      ["question has an invalid shape" | errors]
    end
  end

  defp validate_action_state(errors, payload) do
    question = value(payload, "question") || %{}

    if value(question, "type") == "choose_action" do
      action_state = value(payload, "action_state")
      amount_to_call = if is_map(action_state), do: value(action_state, "amount_to_call_bb")
      street_bet = if is_map(action_state), do: value(action_state, "street_bet_bb")
      hero_contribution = if is_map(action_state), do: value(action_state, "hero_street_contribution_bb")
      contributions = if is_map(action_state), do: value(action_state, "contributions_by_seat_bb")

      if is_number(amount_to_call) and amount_to_call >= 0 and is_number(street_bet) and street_bet >= 0 and
           is_number(hero_contribution) and hero_contribution >= 0 and is_list(contributions) do
        errors
      else
        ["action_state needs non-negative amount_to_call_bb, street_bet_bb, hero_street_contribution_bb, and contributions_by_seat_bb for action questions" | errors]
      end
    else
      errors
    end
  end

  defp validate_remaining_stack(errors, starting_stack, remaining_stack) do
    cond do
      not is_number(remaining_stack) or remaining_stack < 0 -> ["hero.remaining_stack_bb must be non-negative" | errors]
      is_number(starting_stack) and remaining_stack > starting_stack -> ["hero.remaining_stack_bb cannot exceed hero.starting_stack_bb" | errors]
      true -> errors
    end
  end

  defp validate_review(errors, payload) do
    status = value(payload, "status")

    if status in ["reviewed", "published"] do
      answer_key = value(payload, "answer_key")
      review = value(payload, "review")

      errors =
        if is_map(answer_key), do: errors, else: ["answer_key is required after draft" | errors]

      if is_map(review) and is_binary(value(review, "reviewer")) and String.trim(value(review, "reviewer")) != "" and
           value(review, "approved") == true and is_binary(value(review, "reviewed_at")) and
           String.trim(value(review, "reviewed_at")) != "" do
        errors
      else
        ["reviewer and reviewed_at are required after draft" | errors]
      end
    else
      errors
    end
  end

  defp value(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, String.to_atom(key))
    end
  end

  defp map_value(map, key) when is_map(map), do: value(map, key)
  defp map_value(_map, _key), do: nil
end
