defmodule Zoonk.Content.PokerHealth do
  @moduledoc """
  Tracks total chips for the Play battle health bars.

  Bets and calls move chips between a player's stack and the pot, so health only
  changes when a hand result settles. Chips above the original 100 extend into
  the gold segment.
  """

  @starting_chips 100.0
  @hero_blind 5.0
  @bot_blind 10.0

  def starting_chips, do: @starting_chips

  def settle(%{winner: winner, is_tie: is_tie, hero_stack: hero_stack, bot_stack: bot_stack}) when is_integer(winner) or is_tie do
    match_over? = hero_stack <= @hero_blind or bot_stack <= @bot_blind

    {hero_chips, bot_chips} =
      if match_over? do
        total_chips = hero_stack + bot_stack
        if hero_stack > bot_stack, do: {total_chips, 0.0}, else: {0.0, total_chips}
      else
        {hero_stack, bot_stack}
      end

    {:settled, hero_chips, bot_chips, match_over?}
  end

  def settle(_view), do: :in_progress

  def green_width(chips), do: max(0, min(100, round(chips)))
  def gold_width(chips), do: max(0, min(100, round(chips - @starting_chips)))
end
