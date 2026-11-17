defmodule Zoonk.Content.HoldemCurriculumTest do
  use ExUnit.Case, async: true

  alias Zoonk.Content.HoldemCurriculum
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.PokerRules
  alias Zoonk.Content.StepOption

  test "includes the three MVP tracks and their checkpoints" do
    tracks = HoldemCurriculum.tracks()

    assert Enum.map(tracks, &length(&1.lessons)) == [4, 5, 5]

    assert Enum.map(tracks, fn track ->
             Enum.count(track.lessons, & &1.checkpoint?)
           end) == [1, 1, 1]
  end

  test "every lesson has a teaching example, runnable questions, and a finish state" do
    for track <- HoldemCurriculum.tracks(), lesson <- track.lessons do
      steps = lesson |> HoldemCurriculum.lesson_with_steps() |> Map.fetch!(:steps)

      assert hd(steps).kind == :readonly
      assert Enum.any?(steps, &String.contains?(&1.content, "Worked example:"))
      assert List.last(steps).kind == :readonly

      quiz_steps = Enum.filter(steps, &(&1.kind == :quiz))
      assert length(quiz_steps) >= 2

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

  test "hand-ranking answer keys agree with the deterministic evaluator" do
    ranking_scenarios =
      for track <- HoldemCurriculum.tracks(),
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
