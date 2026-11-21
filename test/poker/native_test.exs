defmodule Zoonk.Poker.NativeTest do
  use ExUnit.Case, async: true

  alias Zoonk.Poker.Native

  test "the native evaluator ranks a known straight flush" do
    rank = Native.rank_hand("AsKsQsJsTs")
    assert rank =~ "StraightFlush"
  end

  test "the native Hold'em arena can complete a heads-up simulation" do
    assert "Complete" = Native.simulate_calling_agents()
  end

  test "the tournament engine starts a six-player hand with rotating blind positions" do
    stacks = List.duplicate(2_500.0, 6)
    {_session, view} = Native.start_tournament_hand(stacks, 0, 10.0, 20.0)

    assert view.round == "Preflop"
    assert view.dealer_idx == 0
    assert view.small_blind_idx == 1
    assert view.big_blind_idx == 2
    assert view.acting_player == 3
    assert length(view.player_stacks) == 6
    assert length(view.player_hole_cards) == 6
    assert Enum.all?(view.player_hole_cards, &(&1 == []))
    assert length(view.hero_cards) == 2
    assert Enum.at(view.player_stacks, 1) == 2_490.0
    assert Enum.at(view.player_stacks, 2) == 2_480.0
    assert view.pot == 30.0
  end

  test "a human call pauses through the NIF while the bot advances to the flop" do
    {session, preflop} = Native.start_human_hand()

    assert preflop.round == "Preflop"
    assert preflop.acting_player == 0
    assert preflop.human_action_enabled
    assert preflop.to_call == 5.0
    assert length(preflop.hero_cards) == 2
    assert preflop.bot_cards == []

    flop = Native.human_action(session, "call", 0.0)

    assert flop.round == "Flop"
    assert flop.acting_player == 0
    assert flop.human_action_enabled
    assert flop.pot == 20.0
    assert flop.to_call == 0.0
    assert length(flop.board) == 3
  end

  test "check-through deals the turn and river and settles a five-card board" do
    {session, _preflop} = Native.start_human_hand()
    flop = Native.human_action(session, "call", 0.0)

    assert flop.round == "Flop"
    turn = Native.human_action(session, "check", 0.0)
    assert turn.round == "Turn"
    assert length(turn.board) == 4
    assert turn.human_action_enabled

    river = Native.human_action(session, "check", 0.0)
    assert river.round == "River"
    assert length(river.board) == 5
    assert river.human_action_enabled

    result = Native.human_action(session, "check", 0.0)
    assert result.round == "Complete"
    assert length(result.board) == 5
    assert length(result.bot_cards) == 2
    refute result.human_action_enabled
    assert result.hero_stack + result.bot_stack == 200.0

    if result.is_tie do
      assert is_nil(result.winner)
      assert result.hero_stack == result.bot_stack
    else
      assert result.winner in [0, 1]

      assert (result.winner == 0 and result.hero_stack > result.bot_stack) or
               (result.winner == 1 and result.bot_stack > result.hero_stack)
    end
  end

  test "an invalid raise leaves the same session available for a valid action" do
    {session, _preflop} = Native.start_human_hand()

    assert_raise ArgumentError, fn ->
      Native.human_action(session, "check", 0.0)
    end

    assert_raise ArgumentError, fn ->
      Native.human_action(session, "raise", 11.0)
    end

    assert_raise ArgumentError, fn ->
      Native.human_action(session, "raise", 100.0)
    end

    flop = Native.human_action(session, "call", 0.0)
    assert flop.round == "Flop"
  end

  test "a legal raise is applied before the bot calls" do
    {session, _preflop} = Native.start_human_hand()

    flop = Native.human_action(session, "raise", 20.0)

    assert flop.round == "Flop"
    assert flop.pot == 40.0
    assert flop.hero_stack == 80.0
    assert flop.bot_stack == 80.0
    assert length(flop.board) == 3
  end

  test "a postflop raise advances to the turn with the correct pot and stacks" do
    {session, _preflop} = Native.start_human_hand()
    _flop = Native.human_action(session, "call", 0.0)

    turn = Native.human_action(session, "raise", 20.0)

    assert turn.round == "Turn"
    assert turn.pot == 60.0
    assert turn.hero_stack == 70.0
    assert turn.bot_stack == 70.0
    assert length(turn.board) == 4
    assert turn.human_action_enabled
  end

  test "a human fold ends the heads-up hand" do
    {session, _preflop} = Native.start_human_hand()

    complete = Native.human_action(session, "fold", 0.0)

    assert complete.round == "Complete"
    assert complete.pot == 15.0
    assert complete.hero_stack == 95.0
    assert complete.bot_stack == 105.0
    assert complete.winner == 1
    assert complete.bot_cards == []

    assert_raise ArgumentError, fn ->
      Native.human_action(session, "call", 0.0)
    end
  end
end
