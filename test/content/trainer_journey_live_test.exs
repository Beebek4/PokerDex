defmodule ZoonkWeb.TrainerJourneyLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content

  alias Zoonk.Content
  alias Zoonk.Content.HoldemCurriculum

  setup :app_setup

  defp add_track(school, slug, name) do
    course =
      course_fixture(%{
        school_id: school.id,
        slug: slug,
        name: name,
        description: "A short authored Hold’em track."
      })

    lesson = lesson_fixture(%{course_id: course.id, name: "First lesson", description: "Learn and practise.", order: 1})
    %{course: course, lesson: lesson}
  end

  test "Home prioritizes Play and keeps learning secondary", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/home")

    assert has_element?(lv, "h1", "Ready to play")
    assert has_element?(lv, "h2", "Take your seat.")
    assert has_element?(lv, "a[href='/play']", "Play now")
    assert has_element?(lv, "a[href='/practice']", "Puzzles")
    assert has_element?(lv, "a[href='/courses']", "Theory")
    assert has_element?(lv, "a[href='/progress']", "Progress")
    refute has_element?(lv, "body", "Bot table in development")
  end

  test "Puzzles lets the learner choose a street and play a random lesson", %{conn: conn, school: school} do
    %{course: course} = add_track(school, "holdem-puzzles-preflop", "Preflop puzzles")

    intermediate_lesson =
      lesson_fixture(%{
        course_id: course.id,
        name: "Intermediate hand",
        description: "A more involved preflop spot.",
        difficulty: :intermediate,
        order: 2
      })

    {:ok, lv, _html} = live(conn, ~p"/practice")

    assert has_element?(lv, "h1", "Puzzles")
    assert has_element?(lv, "p", "Just Play")
    assert has_element?(lv, "h2", "Jump into a puzzle")
    assert has_element?(lv, "#puzzle-difficulty")
    assert has_element?(lv, "a[href*='pool=all']", "Play a hand")
    assert has_element?(lv, "#puzzles-preflop", "Play")
    assert has_element?(lv, "#puzzles-flop", "Flop")
    assert has_element?(lv, "#puzzles-turn", "Coming soon")
    assert has_element?(lv, "#puzzles-river", "Coming soon")
    assert has_element?(lv, "#puzzles-showdown", "Showdown")

    lv |> element("#puzzle-difficulty") |> render_change(%{"difficulty" => "intermediate"})
    refute has_element?(lv, "#puzzles-preflop", "available")
    assert has_element?(lv, "a[href*='pool=all'][href*='difficulty=intermediate']", "Play a hand")
    lv |> element("#puzzles-preflop button", "Play") |> render_click()
    assert_redirect(lv, ~p"/c/#{course.slug}/#{intermediate_lesson.id}?difficulty=intermediate")
  end

  test "Progress shows puzzle accuracy, completions, and a street breakdown", %{conn: conn, school: school, user: user} do
    %{lesson: lesson} = add_track(school, "holdem-flop-decisions", "Flop decisions")
    question = HoldemCurriculum.tracks() |> hd() |> Map.fetch!(:lessons) |> hd() |> Map.fetch!(:questions) |> Enum.at(1)
    scenario = question.poker_scenario
    step = lesson_step_fixture(%{lesson_id: lesson.id, content: question.content, kind: :quiz, poker_scenario: scenario})

    {:ok, _selection} =
      Content.add_user_selection(%{
        user_id: user.id,
        lesson_id: lesson.id,
        step_id: step.id,
        duration: 12,
        correct: 1,
        total: 1,
        score: 70,
        scenario_version: 1,
        scenario_snapshot: scenario
      })

    {:ok, lv, _html} = live(conn, ~p"/progress")

    assert has_element?(lv, "h1", "Progress")
    assert has_element?(lv, "h2", "Puzzles")
    assert has_element?(lv, "#puzzles-progress", "100%")
    assert has_element?(lv, "#puzzles-progress", "1")
    assert has_element?(lv, "#puzzles-progress summary", "By street")
    assert has_element?(lv, "#puzzles-progress", "#{String.capitalize(scenario["street"])} · 1 completed")
  end

  test "Theory progress shows completion, accuracy, and a difficulty breakdown", %{conn: conn, school: school, user: user} do
    course =
      course_fixture(%{
        school_id: school.id,
        slug: "theory-module-00-foundations",
        name: "Poker foundations",
        level: :beginner
      })

    completed_lesson = lesson_fixture(%{course_id: course.id, name: "Hand rankings", order: 1})
    lesson_fixture(%{course_id: course.id, name: "Using the board", order: 2})

    step = lesson_step_fixture(%{lesson_id: completed_lesson.id, content: "Question", kind: :quiz})

    {:ok, _selection} =
      Content.add_user_selection(%{
        user_id: user.id,
        lesson_id: completed_lesson.id,
        step_id: step.id,
        duration: 5,
        correct: 1,
        total: 1
      })

    {:ok, _user_lesson} = Content.mark_lesson_as_completed(user.id, completed_lesson.id, 60)

    {:ok, lv, _html} = live(conn, ~p"/progress")

    assert has_element?(lv, "#theory-progress", "50%")
    assert has_element?(lv, "#theory-progress", "100%")
    assert has_element?(lv, "#theory-progress summary", "By difficulty")
    assert has_element?(lv, "#theory-progress", "Beginner · lessons 50%")
  end

  test "missed skills open a different authored review scenario and restore its answer after refresh", %{conn: conn, school: school, user: user} do
    %{course: course, lesson: lesson} = add_track(school, "holdem-review", "Review practice")
    question = HoldemCurriculum.tracks() |> hd() |> Map.fetch!(:lessons) |> hd() |> Map.fetch!(:questions) |> Enum.at(1)
    source_scenario = question.poker_scenario
    source_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: question.content, kind: :quiz, poker_scenario: source_scenario})
    source_option = Enum.find(question.options, &(&1.score < 70))
    source_answer = step_option_fixture(Map.put(source_option, :lesson_step_id, source_step.id))

    alternate_scenario = Map.put(source_scenario, "scenario_id", "#{source_scenario["scenario_id"]}-review-alt")
    alternate_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 2, content: question.content, kind: :quiz, poker_scenario: alternate_scenario})
    alternate_option = Enum.find(question.options, &(&1.score >= 70))
    saved_option = step_option_fixture(Map.put(alternate_option, :lesson_step_id, alternate_step.id))

    {:ok, _selection} =
      Content.add_user_selection(%{
        user_id: user.id,
        lesson_id: lesson.id,
        step_id: source_step.id,
        option_id: source_answer.id,
        duration: 8,
        correct: 0,
        total: 1,
        score: source_option.score,
        scenario_version: source_scenario["version"],
        scenario_snapshot: source_scenario
      })

    review_path = ~p"/review/#{course.slug}/#{lesson.id}/#{alternate_step.id}"
    {:ok, review, _html} = live(conn, review_path)
    # Poker decisions are presented through the table state and action summary,
    # without repeating the question as a heading above the board.
    assert has_element?(review, "section[aria-label='Poker scenario']")
    assert has_element?(review, ".puzzle-scenario-actions")

    review |> form("#review-answer", %{selected_option: saved_option.id}) |> render_submit()
    assert has_element?(review, "h3", if(saved_option.score >= 100, do: "Strong choice", else: "Reasonable alternative"))
    assert Content.get_lesson_resume_order(user.id, lesson.id) == source_step.order
    assert Enum.all?(Content.list_user_selections_by_lesson(user.id, lesson.id, 10), &(&1.activity_type == "lesson"))

    {:ok, refreshed_review, _html} = live(conn, review_path)
    assert has_element?(refreshed_review, "h3", if(saved_option.score >= 100, do: "Strong choice", else: "Reasonable alternative"))
    refreshed_review |> element("button", "Done with review") |> render_click()
    assert_redirect(refreshed_review, ~p"/progress")
  end
end
