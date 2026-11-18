defmodule ZoonkWeb.Live.Practice do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content

  @track_slugs ~w(holdem-puzzles-preflop holdem-puzzles-flop holdem-puzzles-turn holdem-puzzles-river holdem-puzzles-showdown)
  @difficulty_labels [beginner: "Beginner", intermediate: "Intermediate", advanced: "Advanced"]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    school = socket.assigns.school

    tracks =
      school
      |> Content.list_public_courses_by_school(:en)
      |> Enum.map(& &1.data)
      |> Enum.filter(&(&1.slug in @track_slugs))
      |> Enum.sort_by(fn course -> Enum.find_index(@track_slugs, &(&1 == course.slug)) end)
      |> Enum.map(fn course -> %{course: course, lessons: Content.list_published_lessons(course, socket.assigns.current_user)} end)

    tracks_by_slug = Map.new(tracks, &{&1.course.slug, &1})
    preflop = Map.get(tracks_by_slug, "holdem-puzzles-preflop", %{course: nil, lessons: []})
    flop = Map.get(tracks_by_slug, "holdem-puzzles-flop", %{course: nil, lessons: []})
    turn = Map.get(tracks_by_slug, "holdem-puzzles-turn", %{course: nil, lessons: []})
    river = Map.get(tracks_by_slug, "holdem-puzzles-river", %{course: nil, lessons: []})
    showdown = Map.get(tracks_by_slug, "holdem-puzzles-showdown", %{course: nil, lessons: []})

    sections = [
      %{
        key: "preflop",
        title: "Preflop",
        accent: "bg-gray-500",
        lessons: lesson_entries(preflop, :all)
      },
      %{
        key: "flop",
        title: "Flop",
        accent: "bg-gray-400",
        lessons: lesson_entries(flop, :all)
      },
      %{
        key: "turn",
        title: "Turn",
        accent: "bg-gray-300 text-gray-800",
        lessons: lesson_entries(turn, :all)
      },
      %{
        key: "river",
        title: "River",
        accent: "bg-indigo-500",
        lessons: lesson_entries(river, :all)
      },
      %{
        key: "showdown",
        title: "Showdown",
        accent: "bg-indigo-900",
        lessons: lesson_entries(showdown, :all)
      }
    ]

    difficulty_options = available_difficulty_options(sections)
    sections = assign_play_lessons(sections, :any)
    quick_play = random_play_lesson(sections)

    {:ok,
     socket
     |> assign(:page_title, "Puzzles")
     |> assign(:sections, sections)
     |> assign(:difficulty_options, difficulty_options)
     |> assign(:selected_difficulty, :any)
     |> assign(:quick_play, quick_play)
     |> assign(:quick_play_path, quick_play_path(quick_play, :any))}
  end

  @impl Phoenix.LiveView
  def handle_event("set-difficulty", %{"difficulty" => value}, socket) do
    difficulty =
      Enum.find_value(socket.assigns.difficulty_options, :any, fn {key, _label} ->
        if Atom.to_string(key) == value, do: key
      end)

    sections = assign_play_lessons(socket.assigns.sections, difficulty)
    quick_play = random_play_lesson(sections)

    {:noreply,
     socket
     |> assign(:selected_difficulty, difficulty)
     |> assign(:sections, sections)
     |> assign(:quick_play, quick_play)
     |> assign(:quick_play_path, quick_play_path(quick_play, difficulty))}
  end

  def handle_event("play-street", %{"street" => street}, socket) do
    case Enum.find(socket.assigns.sections, &(&1.key == street)) do
      %{play_lessons: [_ | _] = candidates} ->
        %{course: course, lesson: lesson} = Enum.random(candidates)
        {:noreply, push_navigate(socket, to: street_play_path(%{course: course, lesson: lesson}, socket.assigns.selected_difficulty))}

      _ ->
        {:noreply, socket}
    end
  end

  defp lesson_entries(%{course: nil}, _orders), do: []

  defp lesson_entries(track, :all) do
    Enum.map(track.lessons, &%{course: track.course, lesson: &1})
  end

  defp available_difficulty_options(sections) do
    available =
      sections
      |> Enum.flat_map(& &1.lessons)
      |> Enum.map(& &1.lesson.difficulty)
      |> Enum.uniq()

    [{:any, "Any level"} | Enum.filter(@difficulty_labels, fn {level, _label} -> level in available end)]
  end

  defp assign_play_lessons(sections, :any) do
    Enum.map(sections, &Map.put(&1, :play_lessons, &1.lessons))
  end

  defp assign_play_lessons(sections, difficulty) do
    Enum.map(sections, fn section ->
      candidates = Enum.filter(section.lessons, &(&1.lesson.difficulty == difficulty))
      Map.put(section, :play_lessons, candidates)
    end)
  end

  defp random_play_lesson(sections) do
    candidates = Enum.flat_map(sections, & &1.play_lessons)
    if candidates == [], do: nil, else: Enum.random(candidates)
  end

  defp quick_play_path(nil, _difficulty), do: nil

  defp quick_play_path(%{course: course, lesson: lesson}, :any) do
    ~p"/c/#{course.slug}/#{lesson.id}?pool=all"
  end

  defp quick_play_path(%{course: course, lesson: lesson}, difficulty) do
    ~p"/c/#{course.slug}/#{lesson.id}?pool=all&difficulty=#{difficulty}"
  end

  defp street_play_path(%{course: course, lesson: lesson}, :any) do
    ~p"/c/#{course.slug}/#{lesson.id}"
  end

  defp street_play_path(%{course: course, lesson: lesson}, difficulty) do
    ~p"/c/#{course.slug}/#{lesson.id}?difficulty=#{difficulty}"
  end
end
