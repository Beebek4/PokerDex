defmodule ZoonkWeb.Live.LessonCompleted do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias Zoonk.Content.UserLesson

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course, lesson: lesson, current_user: user} = socket.assigns

    user_lesson = Content.get_user_lesson(user.id, lesson.id)

    if is_nil(user_lesson), do: raise(ZoonkWeb.PermissionError, code: :permission_denied)

    scenario_attempts =
      user.id
      |> Content.list_user_selections_by_lesson(lesson.id, Content.count_lesson_steps(lesson.id))
      |> Enum.filter(&(is_integer(&1.score) and is_map(&1.scenario_snapshot)))

    poker_metrics = summarize_scenario_attempts(scenario_attempts)

    next_lesson =
      course
      |> Content.list_published_lessons(user)
      |> Enum.find(&(&1.order > lesson.order))

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:user_lesson, user_lesson)
      |> assign(:poker_metrics, poker_metrics)
      |> assign(:next_lesson, next_lesson)

    {:ok, socket}
  end

  # for readonly steps, correct and total will be 0, so we want to display a 10 score
  defp get_score(%UserLesson{correct: 0, total: 0}), do: 10.0
  defp get_score(%UserLesson{correct: correct, total: total}), do: Float.round(correct / total * 10, 1)

  defp score_title(score) when score == 10.0, do: dgettext("courses", "Perfect!")
  defp score_title(score) when score >= 9.0, do: dgettext("courses", "Excellent!")
  defp score_title(score) when score >= 8.0, do: dgettext("courses", "Very good!")
  defp score_title(score) when score >= 7.0, do: dgettext("courses", "Good!")
  defp score_title(score) when score >= 6.0, do: dgettext("courses", "Not bad!")
  defp score_title(_score), do: dgettext("courses", "There's room for improvement")

  defp score_image(score) when score == 10.0, do: ~p"/images/lessons/perfect.svg"
  defp score_image(score) when score >= 7.0, do: ~p"/images/lessons/good.svg"
  defp score_image(_score), do: ~p"/images/lessons/improve.svg"

  defp win?(score), do: score >= 6.0

  defp badge_color(score) when score >= 8, do: :success
  defp badge_color(score) when score >= 6, do: :warning
  defp badge_color(_score), do: :alert

  defp summarize_scenario_attempts(attempts) do
    actions = Enum.filter(attempts, &(get_in(&1.scenario_snapshot, ["question", "type"]) == "choose_action"))
    rankings = Enum.filter(attempts, &(get_in(&1.scenario_snapshot, ["question", "type"]) == "hand_ranking"))

    %{
      action_count: length(actions),
      action_average: average(Enum.map(actions, & &1.score)),
      ranking_count: length(rankings),
      ranking_correct: Enum.sum(Enum.map(rankings, & &1.correct))
    }
  end

  defp average([]), do: nil
  defp average(scores), do: scores |> Enum.sum() |> Kernel./(length(scores)) |> Float.round(1)
end
