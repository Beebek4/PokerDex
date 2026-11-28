defmodule Zoonk.Poker.BlindSchedule do
  @moduledoc "Blind levels and escalation rules for PokerDex matches."

  @tournament_hands_per_level 8
  @heads_up_hands_per_level 6
  @tournament_levels [{3, 6}, {4, 8}, {6, 12}, {8, 16}, {12, 24}, {18, 36}, {25, 50}, {40, 80}, {50, 100}]
  @heads_up_multipliers [1, 2, 3, 4, 6, 8, 12, 16, 20]

  @doc "Returns the small and big blind for a tournament level, capped at the final level."
  def tournament_at(level) when is_integer(level) and level >= 0 do
    Enum.at(@tournament_levels, min(level, length(@tournament_levels) - 1))
  end

  def tournament_at(_level), do: hd(@tournament_levels)

  @doc "Scales an opponent's configured opening blinds for a heads-up level."
  def heads_up_at(level, {small_blind, big_blind}) when is_integer(level) and level >= 0 do
    multiplier = Enum.at(@heads_up_multipliers, min(level, length(@heads_up_multipliers) - 1))
    {small_blind * multiplier, big_blind * multiplier}
  end

  def heads_up_at(_level, starting_blinds), do: starting_blinds

  @doc "Advances tournament blinds after an elimination or eight completed hands."
  def advance_tournament?(level, completed_hands_at_level, eliminated?) do
    level < length(@tournament_levels) - 1 and
      (eliminated? or completed_hands_at_level >= @tournament_hands_per_level)
  end

  @doc "Advances heads-up blinds after six completed hands at a level."
  def advance_heads_up?(level, completed_hands_at_level) do
    level < length(@heads_up_multipliers) - 1 and
      completed_hands_at_level >= @heads_up_hands_per_level
  end
end
