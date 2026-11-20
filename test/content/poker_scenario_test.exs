defmodule Zoonk.Content.PokerScenarioTest do
  use ExUnit.Case, async: true

  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.PokerScenario
  alias Zoonk.Content.StepOption
  alias Zoonk.Content.UserSelection

  @published_scenario %{
    "scenario_id" => "a-preflop-open",
    "version" => 1,
    "status" => "published",
    "format" => "six_max_cash",
    "table" => %{"seat_count" => 6, "button_seat" => 4, "players_in_hand" => 6},
    "hero" => %{
      "seat" => 2,
      "position" => "cutoff",
      "starting_stack_bb" => 100,
      "remaining_stack_bb" => 100,
      "hole_cards" => ["As", "Kd"]
    },
    "effective_stack_bb" => 100,
    "blinds" => %{"small_blind" => 0.5, "big_blind" => 1, "ante" => 0, "straddle" => 0},
    "street" => "preflop",
    "board" => [],
    "pot" => 1.5,
    "action_history" => [],
    "action_state" => %{
      "amount_to_call_bb" => 1,
      "street_bet_bb" => 1,
      "hero_street_contribution_bb" => 0,
      "contributions_by_seat_bb" => [0.5, 0, 0, 0, 1, 0]
    },
    "legal_actions" => ["fold", "call", "raise"],
    "question" => %{"type" => "choose_action", "prompt" => "What should Hero do?"},
    "assumptions" => ["All players use a 100 big blind effective stack."],
    "skill_tags" => ["preflop.opening"],
    "answer_key" => %{"rationale" => "Open a strong hand from late position."},
    "review" => %{"reviewer" => "Poker reviewer", "approved" => true, "reviewed_at" => "2026-11-17"}
  }

  test "accepts a published scenario with required context and review metadata" do
    assert PokerScenario.validate(@published_scenario) == []
    assert PokerScenario.version(@published_scenario) == 1
  end

  test "rejects incomplete published scenarios" do
    scenario = Map.delete(@published_scenario, "review")
    errors = PokerScenario.validate(scenario)

    assert "reviewer and reviewed_at are required after draft" in errors
  end

  test "lesson step changesets validate a supplied poker scenario" do
    attrs = %{
      content: "What should Hero do?",
      kind: :quiz,
      lesson_id: 1,
      order: 1,
      poker_scenario: @published_scenario
    }

    assert LessonStep.changeset(%LessonStep{}, attrs).valid?

    invalid_attrs = put_in(attrs, [:poker_scenario, "version"], 0)
    refute LessonStep.changeset(%LessonStep{}, invalid_attrs).valid?
  end

  test "step options accept rubric scores with a label and reject out-of-range scores" do
    attrs = %{title: "Raise", correct?: true, lesson_step_id: 1, score: 100, score_label: "Strong"}

    assert StepOption.changeset(%StepOption{}, attrs).valid?
    refute StepOption.changeset(%StepOption{}, %{attrs | score: 110}).valid?
    refute StepOption.changeset(%StepOption{}, Map.delete(attrs, :score_label)).valid?
  end

  test "user selections keep scenario score, version, and snapshot together" do
    attrs = %{
      duration: 5,
      correct: 1,
      total: 1,
      user_id: 1,
      lesson_id: 1,
      step_id: 1,
      score: 70,
      scenario_version: 1,
      scenario_snapshot: @published_scenario
    }

    assert UserSelection.changeset(%UserSelection{}, attrs).valid?
    refute UserSelection.changeset(%UserSelection{}, Map.delete(attrs, :scenario_snapshot)).valid?
    refute UserSelection.changeset(%UserSelection{}, %{attrs | score: 101}).valid?
  end
end
