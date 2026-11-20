defmodule Zoonk.Content.HoldemCurriculumTest do
  use ExUnit.Case, async: true

  alias Zoonk.Content.HoldemCurriculum
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.PokerRules
  alias Zoonk.Content.StepOption

  test "includes the MVP tracks, street puzzle packs, and theory modules" do
    tracks = HoldemCurriculum.tracks()

    assert Enum.map(Enum.take(tracks, 3), &length(&1.lessons)) == [4, 5, 5]
    puzzle_tracks = Enum.drop(tracks, 3)

    assert Enum.map(puzzle_tracks, & &1.slug) == [
             "holdem-puzzles-preflop",
             "holdem-puzzles-flop",
             "holdem-puzzles-turn",
             "holdem-puzzles-river",
             "holdem-puzzles-showdown"
           ]

    assert Enum.all?(puzzle_tracks, &(length(&1.lessons) == 2))
    theory_tracks = HoldemCurriculum.theory_tracks()
    assert length(theory_tracks) == 14
    assert Enum.map(theory_tracks, & &1.order) == Enum.to_list(0..13)

    for track <- theory_tracks do
      assert track.level in [:beginner, :intermediate, :advanced]
      assert is_atom(track.topic)
      assert track.curriculum_street == nil
      assert track.curriculum_stage == nil
      assert String.starts_with?(track.slug, "theory-module-")
    end

    assert Enum.all?(theory_tracks, fn track -> Enum.all?(track.lessons, &(&1.difficulty == track.level)) end)

    assert Enum.map(Enum.take(tracks, 3), fn track ->
             Enum.count(track.lessons, & &1.checkpoint?)
           end) == [1, 1, 1]
  end

  test "every lesson has a teaching example, runnable questions, and a finish state" do
    for track <- HoldemCurriculum.all_tracks(), lesson <- track.lessons do
      steps = lesson |> HoldemCurriculum.lesson_with_steps() |> Map.fetch!(:steps)
      assert List.last(steps).kind == :readonly

      quiz_steps = Enum.filter(steps, &(&1.kind == :quiz))

      if Map.get(lesson, :puzzle_only?, false) do
        assert hd(steps).kind == :quiz
        assert length(quiz_steps) == 1
      else
        assert hd(steps).kind == :readonly
        assert Enum.any?(steps, &String.contains?(&1.content, "Worked example:"))
        assert length(quiz_steps) >= 2
      end

      for {step, order} <- Enum.with_index(steps, 1) do
        changeset =
          LessonStep.changeset(%LessonStep{}, %{
            content: step.content,
            kind: step.kind,
            lesson_id: 1,
            order: order,
            poker_scenario: Map.get(step, :poker_scenario)
          })

        assert changeset.valid?, "#{lesson.id} step #{order}: #{inspect(changeset.errors)}"

        if scenario = Map.get(step, :poker_scenario) do
          if scenario["question"]["type"] == "choose_action" do
            option_actions = Enum.map(Map.get(step, :options, []), &String.downcase(&1.title))
            assert Enum.sort(option_actions) == Enum.sort(scenario["legal_actions"])
            assert length(option_actions) == length(Enum.uniq(option_actions))
          end
        end

        for option <- Map.get(step, :options, []) do
          assert StepOption.changeset(%StepOption{}, Map.put(option, :lesson_step_id, 1)).valid?
        end
      end
    end
  end

  test "the first preflop puzzle shows the small blind with the button next to Hero" do
    scenario =
      HoldemCurriculum.tracks()
      |> Enum.find(&(&1.slug == "holdem-puzzles-preflop"))
      |> Map.fetch!(:lessons)
      |> hd()
      |> HoldemCurriculum.lesson_with_steps()
      |> Map.fetch!(:steps)
      |> hd()
      |> Map.fetch!(:poker_scenario)

    assert scenario["hero"]["position"] == "small_blind"
    assert scenario["hero"]["seat"] == 5
    assert scenario["table"]["button_seat"] == 4
    assert scenario["version"] == 2
    assert scenario["action_state"]["hero_street_contribution_bb"] == 0.5
    assert scenario["action_state"]["amount_to_call_bb"] == 0.5
    assert scenario["board"] == []
  end

  test "hand-ranking answer keys agree with the deterministic evaluator" do
    ranking_scenarios =
      for track <- HoldemCurriculum.all_tracks(),
          lesson <- track.lessons,
          step <- lesson |> HoldemCurriculum.lesson_with_steps() |> Map.fetch!(:steps),
          scenario = Map.get(step, :poker_scenario),
          is_map(scenario),
          scenario["question"]["type"] == "hand_ranking" do
        scenario
      end

    assert ranking_scenarios != []

    for scenario <- ranking_scenarios do
      cards = scenario["hero"]["hole_cards"] ++ scenario["board"]
      assert {:ok, %{category: category}} = PokerRules.evaluate_hand(cards)
      assert Atom.to_string(category) == scenario["answer_key"]["category"]
    end
  end
end
