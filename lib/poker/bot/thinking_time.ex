defmodule Zoonk.Poker.Bot.ThinkingTime do
  @moduledoc "Style-based, short delays before a bot takes its action."

  alias Zoonk.Poker.Bot.Decision

  @style_ranges %{
    calling: {0, 900},
    tight_passive: {1_200, 3_000},
    loose_passive: {0, 1_800},
    tight_aggressive: {700, 2_500},
    loose_aggressive: {0, 1_700},
    value_heavy: {1_300, 3_000}
  }

  @tournament_style_ranges %{
    calling: {0, 800},
    tight_passive: {1_000, 2_000},
    loose_passive: {0, 1_000},
    tight_aggressive: {600, 1_800},
    loose_aggressive: {0, 900},
    value_heavy: {1_200, 2_000}
  }

  @doc "Returns a randomized 0–3 second pause, adjusted for the bot's action style."
  @spec delay_ms(map(), Decision.t()) :: non_neg_integer()
  def delay_ms(opponent, %Decision{} = decision) do
    randomized_delay(opponent, decision, @style_ranges, 0, 3_000)
  end

  @doc "Returns a style-adjusted tournament pause between zero and two seconds."
  @spec delay_ms(map(), Decision.t(), :tournament) :: non_neg_integer()
  def delay_ms(opponent, %Decision{} = decision, :tournament) do
    randomized_delay(opponent, decision, @tournament_style_ranges, 0, 2_000)
  end

  def delay_ms(opponent, %Decision{} = decision, _mode), do: delay_ms(opponent, decision)

  defp randomized_delay(opponent, decision, ranges, floor, ceiling) do
    {minimum, maximum} = Map.get(ranges, opponent.policy, {floor, ceiling})
    adjustment = action_adjustment(decision.action)
    minimum = clamp(minimum + adjustment, floor, ceiling)
    maximum = clamp(maximum + adjustment, minimum, ceiling)

    minimum + :rand.uniform(maximum - minimum + 1) - 1
  end

  defp action_adjustment("raise"), do: 350
  defp action_adjustment("fold"), do: 150
  defp action_adjustment(_action), do: -150

  defp clamp(value, minimum, maximum), do: value |> max(minimum) |> min(maximum)
end
