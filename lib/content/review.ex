defmodule ZoonkWeb.Live.Review do
  @moduledoc false
  use ZoonkWeb, :live_view

  import ZoonkWeb.Components.Content.LessonStep

  alias Zoonk.Content
  alias Zoonk.Content.PokerScenario

  @impl Phoenix.LiveView
  def mount(%{"step_id" => step_id}, _session, socket) do
    %{lesson: lesson, current_user: user, school: school} = socket.assigns
    step_id = String.to_integer(step_id)
    step = Enum.find(Content.list_lesson_steps(lesson), &(&1.id == step_id and is_map(&1.poker_scenario)))
    pending = if step, do: Content.get_pending_selection_for_step(user.id, step.id)

    review =
      if pending do
        user.id
        |> Content.list_due_review_scenarios(school.id)
        |> Enum.find(&(&1.step.id == step.id))
      else
        user.id
        |> Content.list_due_review_scenarios(school.id)
        |> Enum.find(&(&1.step.id == step_id))
      end

    if is_nil(step) or (is_nil(review) and is_nil(pending)) do
      {:ok, redirect(socket, to: ~p"/progress")}
    else
      scenario = (pending && pending.scenario_snapshot) || step.poker_scenario
      selected = pending && Enum.find(step.options, &(&1.id == pending.option_id))

      step = %{step | poker_scenario: scenario}

      {:ok,
       socket
       |> assign(:page_title, "Skill review")
       |> assign(:review_step, step)
       |> assign(:review_reason, (review && review.reason) || "Finish reviewing your saved answer.")
       |> assign(:selected_option, selected)
       |> assign(:saved_selection, pending)
       |> assign(:selection_saved?, not is_nil(pending))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("answer", %{"selected_option" => option_id}, %{assigns: %{selected_option: nil}} = socket) do
    %{current_user: user, lesson: lesson, review_step: step} = socket.assigns
    selected = Enum.find(step.options, &(Integer.to_string(&1.id) == option_id))

    if selected do
      attrs = %{
        user_id: user.id,
        lesson_id: lesson.id,
        step_id: step.id,
        option_id: selected.id,
        correct: if(selected.correct?, do: 1, else: 0),
        total: 1,
        duration: 0,
        activity_type: "review",
        score: selected.score,
        scenario_version: PokerScenario.version(step.poker_scenario),
        scenario_snapshot: step.poker_scenario,
        acknowledged?: false
      }

      case Content.add_user_selection(attrs) do
        {:ok, selection} ->
          {:noreply,
           socket
           |> assign(:selected_option, selected)
           |> assign(:saved_selection, selection)
           |> assign(:selection_saved?, true)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Unable to save this answer. Please try again.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Choose one of the available actions.")}
    end
  end

  def handle_event("done", _params, %{assigns: %{saved_selection: %{id: selection_id}}} = socket) do
    case Content.acknowledge_user_selection(selection_id) do
      {:ok, _selection} -> {:noreply, push_navigate(socket, to: ~p"/progress")}
      {:error, _changeset} -> {:noreply, put_flash(socket, :error, "Unable to save your progress. Please try again.")}
    end
  end

  def handle_event("done", _params, socket), do: {:noreply, push_navigate(socket, to: ~p"/progress")}
end
