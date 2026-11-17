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

  test "Home prioritizes the next lesson and lists tracks", %{conn: conn, school: school} do
    %{course: course, lesson: lesson} = add_track(school, "holdem-start-here", "Start here")
    lesson_step_fixture(%{lesson_id: lesson.id, content: "Welcome", kind: :readonly})

    {:ok, lv, _html} = live(conn, ~p"/home")

    assert has_element?(lv, "h1", "Welcome back")
    assert has_element?(lv, "a[href='/c/#{course.slug}/#{lesson.id}']", "Start lesson")
    assert has_element?(lv, "a[href='/c/#{course.slug}']", "View track")
    assert has_element?(lv, "a[href='/practice']", "Puzzles")
    assert has_element?(lv, "a[href='/progress']", "Progress")
  end

  test "Practice lists available tracks", %{conn: conn, school: school} do
    %{course: course} = add_track(school, "holdem-preflop", "Preflop fundamentals")

    {:ok, lv, _html} = live(conn, ~p"/practice")

    assert has_element?(lv, "h1", "Just Play")
    assert has_element?(lv, "h2", "Preflop Fundamentals")
    assert has_element?(lv, "a[href='/c/#{course.slug}']", "Open")
  end

  test "Progress separates action rubric scores from objective hand-ranking accuracy", %{conn: conn, school: school, user: user} do
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

    assert has_element?(lv, "h1", "Your practice so far")
    assert has_element?(lv, "p", "Action decisions")
    assert has_element?(lv, "p", "70.0 / 100 average rubric score")
    refute has_element?(lv, "p", "0 / 1 correct")
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

    {:ok, progress, _html} = live(conn, ~p"/progress")
    assert has_element?(progress, "h2", "Review a skill you missed")
    assert has_element?(progress, "p", "Your latest action score for this skill was #{source_option.score}/100.")

    review_path = ~p"/review/#{course.slug}/#{lesson.id}/#{alternate_step.id}"
    {:ok, review, _html} = live(conn, review_path)
    assert has_element?(review, "h2", get_in(alternate_scenario, ["question", "prompt"]))

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
