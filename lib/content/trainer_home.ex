defmodule ZoonkWeb.Live.TrainerHome do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias Zoonk.Content.CourseUtils

  @track_slugs ~w(holdem-start-here holdem-preflop holdem-flop-decisions)

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user, school: school} = socket.assigns
    tracks = load_tracks(school, user)
    next_lesson = next_lesson(tracks, user)

    due_review =
      if is_nil(next_lesson) or not next_lesson.resume? do
        user.id |> Content.list_due_review_scenarios(school.id) |> List.first()
      end

    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:tracks, tracks)
      |> assign(:next_lesson, next_lesson)
      |> assign(:due_review, due_review)
      |> assign(:resume?, not is_nil(next_lesson) and next_lesson.resume?)

    {:ok, socket}
  end

  defp load_tracks(school, user) do
    school
    |> Content.list_public_courses_by_school(:en)
    |> Enum.map(& &1.data)
    |> Enum.filter(&(&1.slug in @track_slugs))
    |> Enum.sort_by(fn course -> Enum.find_index(@track_slugs, &(&1 == course.slug)) end)
    |> Enum.map(fn course ->
      lessons = Content.list_published_lessons(course, user)
      %{course: course, lessons: lessons, progress: CourseUtils.course_progress(lessons, user)}
    end)
  end

  defp next_lesson(tracks, user) do
    lessons = Enum.flat_map(tracks, fn %{course: course, lessons: lessons} -> Enum.map(lessons, &{course, &1}) end)

    Enum.find_value(lessons, fn {course, lesson} ->
      if not CourseUtils.lesson_completed?(user, lesson.user_lessons) and Content.get_lesson_resume_order(user.id, lesson.id) > 0 do
        %{course: course, lesson: lesson, resume?: true}
      end
    end) ||
      Enum.find_value(lessons, fn {course, lesson} ->
        unless CourseUtils.lesson_completed?(user, lesson.user_lessons), do: %{course: course, lesson: lesson, resume?: false}
      end)
  end
end
