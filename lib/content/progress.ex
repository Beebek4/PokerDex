defmodule ZoonkWeb.Live.Progress do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    attempts = Content.list_user_scenario_attempts(socket.assigns.current_user.id)
    skills = summarize_by_skill(attempts)
    due_reviews = Content.list_due_review_scenarios(socket.assigns.current_user.id, socket.assigns.school.id)

    {:ok,
     socket
     |> assign(:page_title, "Progress")
     |> assign(:attempt_count, length(attempts))
     |> assign(:skills, skills)
     |> assign(:due_reviews, due_reviews)}
  end

  defp summarize_by_skill(attempts) do
    attempts
    |> Enum.reduce(%{}, fn attempt, skills ->
      scenario = attempt.scenario_snapshot
      question_type = get_in(scenario, ["question", "type"])
      tags = Map.get(scenario, "skill_tags", [])

      Enum.reduce(tags, skills, fn tag, skills ->
        stats = Map.get(skills, tag, empty_stats())

        stats =
          case question_type do
            "choose_action" ->
              recent = if length(stats.action_recent) < 5, do: [attempt.score | stats.action_recent], else: stats.action_recent
              %{stats | action_count: stats.action_count + 1, action_score: stats.action_score + attempt.score, action_recent: recent}

            "hand_ranking" ->
              recent = if length(stats.objective_recent) < 5, do: [{attempt.correct, attempt.total} | stats.objective_recent], else: stats.objective_recent
              %{stats | objective_count: stats.objective_count + attempt.total, objective_correct: stats.objective_correct + attempt.correct, objective_recent: recent}

            _ ->
              stats
          end

        Map.put(skills, tag, stats)
      end)
    end)
    |> Enum.sort_by(fn {tag, _stats} -> tag end)
  end

  defp empty_stats do
    %{action_count: 0, action_score: 0, action_recent: [], objective_count: 0, objective_correct: 0, objective_recent: []}
  end
end
