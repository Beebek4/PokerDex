defmodule Zoonk.Poker.Bot.Policy do
  @moduledoc "Explainable baseline bot policy shared by all Home opponents."

  alias Zoonk.Poker.Bot.Decision
  alias Zoonk.Poker.Bot.Difficulty
  alias Zoonk.Poker.Bot.Observation
  alias Zoonk.Poker.Bot.Profiles
  alias Zoonk.Poker.Native

  @doc "Chooses a legal action from a restricted view; `roll` allows repeatable policy checks."
  @spec choose(Observation.t(), map(), String.t(), float()) :: Decision.t()
  def choose(%Observation{} = observation, opponent, difficulty_id, roll \\ :rand.uniform()) do
    style = Profiles.get(opponent.policy)
    difficulty = Difficulty.get(difficulty_id)
    strength = hand_strength(observation)

    cond do
      opponent.policy == :calling ->
        passive_action(observation)

      affordable_mistake_call?(observation) and roll < difficulty.mistake_rate ->
        maybe_call(observation, :loose_mistake)

      observation.to_call > 0 ->
        facing_bet(observation, style, difficulty, strength, roll)

      true ->
        facing_check(observation, style, difficulty, strength, roll)
    end
  end

  def from_game_view(view) do
    %Observation{
      street: view.round,
      hole_cards: view.bot_private_cards,
      board: view.board,
      pot: view.pot,
      stack: view.bot_stack,
      opponent_stack: view.hero_stack,
      to_call: view.to_call,
      min_raise: view.min_raise,
      max_raise: view.max_raise
    }
  end

  defp passive_action(%Observation{to_call: to_call}) when to_call > 0, do: %Decision{action: "call", amount: 0.0, reason: :teddy_calls}

  defp passive_action(_observation), do: %Decision{action: "check", amount: 0.0, reason: :teddy_checks}

  defp facing_bet(observation, style, difficulty, strength, roll) do
    price = observation.to_call / max(observation.pot + observation.to_call, 1.0)
    stack_commitment = min(observation.to_call / max(observation.stack, 1.0), 1.0)
    call_threshold = style.continue + price * 0.16 + stack_commitment * 0.22 + difficulty.call_adjustment

    raise_threshold =
      if observation.street == "Preflop" do
        Map.get(style, :preflop_raise, style.value_bet)
      else
        max(style.value_bet + difficulty.raise_adjustment, call_threshold + 0.12)
      end

    can_raise? = observation.max_raise >= observation.min_raise and observation.min_raise > observation.to_call

    cond do
      can_raise? and strength >= raise_threshold and roll < style.aggression ->
        raise_action(observation, style, :value_raise)

      strength >= call_threshold ->
        %Decision{action: "call", amount: 0.0, reason: :continue_with_hand}

      true ->
        %Decision{action: "fold", amount: 0.0, reason: :fold_to_pressure}
    end
  end

  defp facing_check(observation, style, difficulty, strength, roll) do
    value_threshold =
      if observation.street == "Preflop" do
        Map.get(style, :preflop_raise, style.value_bet)
      else
        max(style.value_bet + difficulty.raise_adjustment, 0.45)
      end

    can_raise? = observation.max_raise >= observation.min_raise
    bluff? = strength < value_threshold and roll < style.bluff

    value_bet? =
      strength >= value_threshold and
        roll < style.aggression + difficulty.aggression_adjustment + difficulty.mistake_rate

    if can_raise? and (value_bet? or bluff?) do
      raise_action(observation, style, if(bluff?, do: :selective_bluff, else: :value_bet))
    else
      %Decision{action: "check", amount: 0.0, reason: :check_when_unpressured}
    end
  end

  defp maybe_call(%Observation{to_call: to_call}, reason) when to_call > 0, do: %Decision{action: "call", amount: 0.0, reason: reason}

  defp maybe_call(_observation, _reason), do: %Decision{action: "check", amount: 0.0, reason: :check_when_unpressured}

  # Easy and standard bots can make occasional loose calls, but those mistakes
  # should not turn into routine calls for most of a tournament stack.
  defp affordable_mistake_call?(%Observation{to_call: to_call, stack: stack}) do
    to_call > 0 and to_call <= max(stack * 0.10, 1.0)
  end

  defp raise_action(observation, style, reason) do
    extra = max(1, round(observation.pot * style.size))
    amount = min(observation.min_raise + extra, observation.max_raise)
    %Decision{action: "raise", amount: amount * 1.0, reason: reason}
  end

  defp hand_strength(%Observation{board: []} = observation), do: preflop_strength(observation.hole_cards)

  defp hand_strength(%Observation{hole_cards: hole_cards, board: board}) do
    case Native.rank_hand(Enum.join(hole_cards ++ board)) do
      "HighCard" -> draw_adjustment(hole_cards, board, 0.16)
      "OnePair" -> draw_adjustment(hole_cards, board, 0.55)
      "TwoPair" -> 0.66
      "ThreeOfAKind" -> 0.79
      "Straight" -> 0.88
      "Flush" -> 0.92
      "FullHouse" -> 0.96
      "FourOfAKind" -> 0.99
      "StraightFlush" -> 1.0
      _ -> 0.2
    end
  end

  defp preflop_strength([first, second]) do
    {rank_a, suit_a} = parse_card(first)
    {rank_b, suit_b} = parse_card(second)
    high = max(rank_a, rank_b)
    low = min(rank_a, rank_b)
    pair? = rank_a == rank_b
    suited? = suit_a == suit_b
    gap = high - low

    strength =
      if pair? do
        0.43 + high / 100
      else
        0.12 + high * 0.026 + low * 0.018 + if(suited?, do: 0.055, else: 0.0) + connector_bonus(gap)
      end

    min(strength, 0.84)
  end

  defp preflop_strength(_cards), do: 0.2

  defp connector_bonus(1), do: 0.075
  defp connector_bonus(2), do: 0.045
  defp connector_bonus(3), do: 0.015
  defp connector_bonus(_gap), do: 0.0

  defp parse_card(<<rank::binary-size(1), suit::binary-size(1)>>) do
    value =
      case rank do
        "A" -> 14
        "K" -> 13
        "Q" -> 12
        "J" -> 11
        "T" -> 10
        digit -> String.to_integer(digit)
      end

    {value, suit}
  end

  defp parse_card(_card), do: {2, "?"}

  defp draw_adjustment(hole_cards, board, strength) do
    suits = Enum.map(hole_cards ++ board, &String.last/1)
    suit_draw? = Enum.any?(~w(c d h s), &(Enum.count(suits, fn suit -> suit == &1 end) >= 4))
    if suit_draw?, do: strength + 0.12, else: strength
  end
end
