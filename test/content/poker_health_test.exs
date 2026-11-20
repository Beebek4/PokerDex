defmodule Zoonk.Content.PokerHealthTest do
  use ExUnit.Case, async: true

  alias Zoonk.Content.PokerHealth

  test "health stays at the last settled amount while a pot is in progress" do
    in_progress = %{
      winner: nil,
      is_tie: false,
      hero_stack: 80.0,
      bot_stack: 80.0
    }

    assert PokerHealth.settle(in_progress) == :in_progress
    assert PokerHealth.green_width(PokerHealth.starting_chips()) == 100
    assert PokerHealth.gold_width(PokerHealth.starting_chips()) == 0
  end

  test "each settled pot updates both health bars and carries chips forward" do
    first_result = %{winner: 1, is_tie: false, hero_stack: 95.0, bot_stack: 105.0}
    assert PokerHealth.settle(first_result) == {:settled, 95.0, 105.0, false}

    assert PokerHealth.green_width(95.0) == 95
    assert PokerHealth.gold_width(105.0) == 5

    next_result = %{winner: 1, is_tie: false, hero_stack: 90.0, bot_stack: 110.0}
    assert PokerHealth.settle(next_result) == {:settled, 90.0, 110.0, false}

    assert PokerHealth.green_width(90.0) == 90
    assert PokerHealth.gold_width(110.0) == 10
  end

  test "a tied pot settles without changing the combined chip total" do
    tied_result = %{winner: nil, is_tie: true, hero_stack: 100.0, bot_stack: 100.0}

    assert PokerHealth.settle(tied_result) == {:settled, 100.0, 100.0, false}
  end

  test "the match ends when a player cannot cover the next blind" do
    hero_loses = %{winner: 1, is_tie: false, hero_stack: 5.0, bot_stack: 195.0}
    assert PokerHealth.settle(hero_loses) == {:settled, 0.0, 200.0, true}

    bot_loses = %{winner: 0, is_tie: false, hero_stack: 195.0, bot_stack: 5.0}
    assert PokerHealth.settle(bot_loses) == {:settled, 200.0, 0.0, true}

    assert PokerHealth.green_width(0.0) == 0
    assert PokerHealth.green_width(200.0) == 100
    assert PokerHealth.gold_width(200.0) == 100
  end
end
