defmodule ZoonkWeb.Live.Progress do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias Zoonk.Content.CourseUtils
  alias Zoonk.Poker.Campaigns

  @theory_difficulties [beginner: "Beginner", intermediate: "Intermediate", advanced: "Advanced"]
  @puzzle_streets ~w(preflop flop turn river showdown)

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    attempts = Content.list_user_scenario_attempts(socket.assigns.current_user.id)
    puzzle_progress = puzzle_progress(attempts)
    theory_progress = theory_progress(socket.assigns.school, socket.assigns.current_user)
    play_progress = Campaigns.get_progress(socket.assigns.current_user.id)

    {:ok,
     socket
     |> assign(:page_title, "Progress")
     |> assign(:puzzle_progress, puzzle_progress)
     |> assign(:theory_progress, theory_progress)
     |> assign(:play_progress, play_progress)}
  end

  defp theory_progress(school, user) do
    lessons =
      school
      |> Content.list_public_courses_by_school(:en)
      |> Enum.map(& &1.data)
      |> Enum.filter(&String.starts_with?(&1.slug, "theory-module-"))
      |> Enum.flat_map(&Content.list_published_lessons(&1, user))

    %{
      overall: summarize_theory_lessons(lessons, user),
      difficulties:
        Enum.flat_map(@theory_difficulties, fn {difficulty, title} ->
          difficulty_lessons = Enum.filter(lessons, &(&1.difficulty == difficulty))
          if difficulty_lessons == [], do: [], else: [%{title: title, stats: summarize_theory_lessons(difficulty_lessons, user)}]
        end)
    }
  end

  defp summarize_theory_lessons(lessons, user) do
    %{
      lessons_percentage: if(lessons == [], do: 0, else: round(Enum.count(lessons, &CourseUtils.lesson_completed?(user, &1.user_lessons)) / length(lessons) * 100)),
      accuracy_percentage: accuracy(Enum.flat_map(lessons, & &1.user_lessons))
    }
  end

  defp puzzle_progress(attempts) do
    attempts_by_street = Enum.group_by(attempts, fn attempt -> get_in(attempt.scenario_snapshot, ["street"]) || "other" end)

    streets =
      Enum.map(@puzzle_streets, fn street ->
        street_attempts = Map.get(attempts_by_street, street, [])

        %{
          title: String.capitalize(street),
          accuracy_percentage: accuracy(street_attempts),
          completed_count: length(street_attempts)
        }
      end)

    %{
      accuracy_percentage: accuracy(attempts),
      completed_count: length(attempts),
      streets: streets
    }
  end

  defp accuracy([]), do: 0

  defp accuracy(records) do
    total = Enum.sum(Enum.map(records, & &1.total))
    correct = Enum.sum(Enum.map(records, & &1.correct))
    if total == 0, do: 0, else: round(correct / total * 100)
  end
end
