defmodule Zoonk.Poker.Opponents do
  @moduledoc "Canonical catalogue for PokerDex's Home opponents and final event."

  @opponents [
    %{
      id: "teddy",
      level: "LEVEL 0 · WARM-UP",
      name: "Teddy",
      personality: "Gentle",
      style: "Check/call",
      policy: :calling,
      difficulty: "easy",
      preview: "Not in the tournament.",
      buy_in: 0,
      small_blind: 5,
      big_blind: 10,
      respect_required: 0,
      respect_reward: 1,
      side: :right
    },
    %{
      id: "grandpa",
      level: "LEVEL 1",
      name: "Grandpa",
      personality: "Patient",
      style: "Tight-passive",
      policy: :tight_passive,
      difficulty: "easy",
      preview: "Few hands, few bluffs; big bets tend strong.",
      buy_in: 100,
      small_blind: 1,
      big_blind: 2,
      respect_required: 1,
      respect_reward: 1,
      side: :left
    },
    %{
      id: "mum",
      level: "LEVEL 2",
      name: "Mum",
      personality: "Social",
      style: "Loose-passive",
      policy: :loose_passive,
      difficulty: "easy",
      preview: "Calls too often; value bet, bluff less.",
      buy_in: 200,
      small_blind: 2,
      big_blind: 4,
      respect_required: 2,
      respect_reward: 1,
      side: :right
    },
    %{
      id: "brother",
      level: "LEVEL 3",
      name: "Brother",
      personality: "Impulsive and unpredictable",
      style: "Loose-aggressive",
      policy: :loose_aggressive,
      difficulty: "standard",
      preview: "Wide range; frequent bets and bluffs.",
      buy_in: 300,
      small_blind: 3,
      big_blind: 6,
      respect_required: 3,
      respect_reward: 1,
      side: :left
    },
    %{
      id: "sister",
      level: "LEVEL 4",
      name: "Sister",
      personality: "Focused",
      style: "Tight-aggressive",
      policy: :tight_aggressive,
      difficulty: "standard",
      preview: "Selective hands, then applies pressure.",
      buy_in: 400,
      small_blind: 4,
      big_blind: 8,
      respect_required: 4,
      respect_reward: 1,
      side: :right
    },
    %{
      id: "dad",
      level: "LEVEL 5 · FINAL HOME MATCH",
      name: "Dad",
      personality: "Steady and readable",
      style: "Straightforward, value-heavy",
      policy: :value_heavy,
      difficulty: "hard",
      preview: "Large bets tend strong; practise disciplined folds.",
      buy_in: 500,
      small_blind: 5,
      big_blind: 10,
      respect_required: 5,
      respect_reward: 1,
      side: :left
    }
  ]

  @tournament %{
    id: "house-tournament",
    name: "Garage Tournament",
    eyebrow: "FINAL EVENT",
    detail: "Face the full family field at one table.",
    personality: "The family field",
    style: "Multiway tournament",
    preview: "A multiway final event for the Home opponents; Teddy sits it out.",
    buy_in: 2500,
    prize_pool: 15_000,
    respect_required: 6,
    respect_reward: 0,
    difficulty: "hard",
    small_blind: 10,
    big_blind: 20
  }

  @doc "Returns the canonical opponent definitions in journey order."
  def all, do: @opponents

  def tournament, do: @tournament

  @doc "Finds an opponent by stable ID."
  def get("house-tournament"), do: @tournament
  def get(id) when is_binary(id), do: Enum.find(@opponents, &(&1.id == id))
  def get(_id), do: nil

  @doc "Builds the displayed journey and derives lock status from campaign state."
  def locations(cash, respect) do
    home_opponents =
      Enum.map(@opponents, fn opponent ->
        opponent
        |> Map.put(:status, status(opponent, cash, respect))
        |> Map.put(:lock_reason, lock_reason(opponent, cash, respect))
      end)

    tournament =
      @tournament
      |> Map.put(:requirements_met?, respect >= @tournament.respect_required and cash >= @tournament.buy_in)
      |> then(fn tournament -> Map.put(tournament, :status, if(tournament.requirements_met?, do: :open, else: :locked)) end)

    [
      %{
        id: "home",
        name: "Home Heads Up",
        eyebrow: "STARTING LOCATION",
        detail: "Meet the family, one table at a time.",
        opponents: home_opponents
      },
      tournament
    ]
  end

  defp status(%{respect_required: required, buy_in: buy_in}, cash, respect) do
    if respect >= required and cash >= buy_in, do: :open, else: :locked
  end

  defp lock_reason(%{respect_required: required}, _cash, respect) when respect < required, do: "Needs #{required} Respect"

  defp lock_reason(%{buy_in: buy_in}, cash, _respect) when cash < buy_in, do: "Needs #{buy_in} chips"

  defp lock_reason(_opponent, _cash, _respect), do: nil
end
