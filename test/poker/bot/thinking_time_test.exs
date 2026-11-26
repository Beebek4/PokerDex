defmodule Zoonk.Poker.Bot.ThinkingTimeTest do
  use ExUnit.Case, async: true

  alias Zoonk.Poker.Bot.Decision
  alias Zoonk.Poker.Bot.ThinkingTime

  @styles [:calling, :tight_passive, :loose_passive, :tight_aggressive, :loose_aggressive, :value_heavy]
  @actions ["check", "call", "fold", "raise"]

  test "heads-up delays stay within zero to three seconds for every style and action" do
    for style <- @styles, action <- @actions, _iteration <- 1..25 do
      delay = ThinkingTime.delay_ms(%{policy: style}, %Decision{action: action, amount: 0, reason: :test})
      assert delay in 0..3_000
    end
  end

  test "tournament delays stay within zero to two seconds for every style and action" do
    for style <- @styles, action <- @actions, _iteration <- 1..25 do
      delay = ThinkingTime.delay_ms(%{policy: style}, %Decision{action: action, amount: 0, reason: :test}, :tournament)
      assert delay in 0..2_000
    end
  end
end
