defmodule ZoonkWeb.Live.Practice do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content

  @track_slugs ~w(holdem-start-here holdem-preflop holdem-flop-decisions)

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
    start_here = Map.get(tracks_by_slug, "holdem-start-here", %{course: nil, lessons: []})
    preflop = Map.get(tracks_by_slug, "holdem-preflop", %{course: nil, lessons: []})
    flop = Map.get(tracks_by_slug, "holdem-flop-decisions", %{course: nil, lessons: []})

    quick_play_lessons =
      Enum.flat_map([preflop, flop], fn track ->
        Enum.map(track.lessons, &%{course: track.course, lesson: &1})
      end)

    sections = [
      %{
        title: "Preflop Fundamentals",
        description: "Practise position, starting hands, and decisions before the flop.",
        cover: ~p"/images/poker/covers/preflop.jpg",
        track: preflop,
        lessons: [],
        lesson_count: length(preflop.lessons)
      },
      %{
        title: "Flop Decisions",
        description: "Read the flop, identify your hand, and choose a plan.",
        cover: ~p"/images/poker/covers/flop.jpg",
        track: flop,
        lessons: [],
        lesson_count: length(flop.lessons)
      },
      %{
        title: "Hold'em Rules",
        description: "Learn how a hand moves around the table and how poker hands are ranked.",
        cover: ~p"/images/poker/covers/holdem-rules.jpg",
        track: start_here,
        lessons: Enum.filter(start_here.lessons, &(&1.order in [1, 2])),
        lesson_count: Enum.count(start_here.lessons, &(&1.order in [1, 2]))
      },
      %{
        title: "Hand Reading",
        description: "Practise reading the board and recognising made hands and draws.",
        cover: ~p"/images/poker/covers/hand-reading.jpg",
        track: start_here,
        lessons: Enum.filter(start_here.lessons, &(&1.order >= 3)),
        lesson_count: Enum.count(start_here.lessons, &(&1.order >= 3))
      }
    ]

    quick_play = if quick_play_lessons == [], do: nil, else: Enum.random(quick_play_lessons)

    {:ok,
     socket
     |> assign(:page_title, "Puzzles")
     |> assign(:sections, sections)
     |> assign(:quick_play, quick_play)}
  end
end
