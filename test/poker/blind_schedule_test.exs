defmodule Zoonk.Poker.BlindScheduleTest do
  use ExUnit.Case, async: true

  alias Zoonk.Poker.BlindSchedule

  test "tournament blind levels rise after eliminations or eight completed hands" do
    assert BlindSchedule.tournament_at(0) == {3, 6}
    assert BlindSchedule.tournament_at(1) == {4, 8}
    refute BlindSchedule.advance_tournament?(0, 7, false)
    assert BlindSchedule.advance_tournament?(0, 8, false)
    assert BlindSchedule.advance_tournament?(0, 1, true)
  end

  test "heads-up blinds rise from each opponent's configured opening blinds" do
    assert BlindSchedule.heads_up_at(0, {1, 2}) == {1, 2}
    assert BlindSchedule.heads_up_at(1, {1, 2}) == {2, 4}
    assert BlindSchedule.heads_up_at(2, {1, 2}) == {3, 6}
    assert BlindSchedule.heads_up_at(1, {2, 4}) == {4, 8}
  end

  test "heads-up blind levels rise after six hands and eventually cap" do
    refute BlindSchedule.advance_heads_up?(0, 5)
    assert BlindSchedule.advance_heads_up?(0, 6)
    refute BlindSchedule.advance_heads_up?(8, 100)
    assert BlindSchedule.heads_up_at(100, {1, 2}) == {20, 40}
  end
end
