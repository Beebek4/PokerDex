defmodule ZoonkWeb.Live.CourseList do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias Zoonk.Content.HoldemTheoryCurriculum

  @levels [
    %{key: :beginner, title: "Beginner path", label: "Beginner"},
    %{key: :intermediate, title: "Intermediate topics", label: "Intermediate"},
    %{key: :advanced, title: "Advanced strategy", label: "Advanced"}
  ]

  @beginner_groups [
    %{key: :start_here, title: "Start here", description: "How a Hold’em hand works and a simple way to think through decisions.", orders: [0, 1]},
    %{key: :preflop, title: "Preflop: position and ranges", description: "Build a plan before the community cards are dealt.", orders: [2]},
    %{key: :hand_reading, title: "Hands and board reading", description: "Recognise made hands, draws, and how the board connects with ranges.", orders: [3, 4]},
    %{key: :betting, title: "Betting and responses", description: "Learn why to bet, how sizing changes the price, and how to respond.", orders: [5, 6]},
    %{key: :later_streets, title: "Turn and river", description: "Reassess the hand as new cards arrive and plan the final decisions.", orders: [7]},
    %{key: :review, title: "Review your decisions", description: "Learn from the reasoning without letting the result rewrite the decision.", orders: [13]}
  ]

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    %{school: school} = socket.assigns

    courses = Content.list_public_courses_by_school(school, session["locale"])
    courses_by_slug = Map.new(courses, &{&1.data.slug, &1})

    modules =
      Enum.map(HoldemTheoryCurriculum.modules(), fn module ->
        %{
          course_data: Map.get(courses_by_slug, module.slug),
          lessons: module.lessons,
          order: module.order,
          topic: module.topic,
          level: module.level,
          name: module.name,
          description: module.description,
          slug: module.slug
        }
      end)

    sections =
      Enum.map(@levels, fn level ->
        modules = Enum.filter(modules, &(&1.level == level.key))
        Map.put(level, :modules, modules)
      end)

    beginner_groups =
      Enum.map(@beginner_groups, fn group ->
        group_modules = Enum.filter(modules, &(&1.order in group.orders))
        Map.put(group, :modules, group_modules)
      end)

    socket =
      socket
      |> assign(:page_title, gettext("Theory"))
      |> assign(:sections, sections)
      |> assign(:beginner_groups, beginner_groups)
      |> assign(:levels, @levels)
      |> assign(:selected_level, "all")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("filter-level", %{"level" => level}, socket) do
    selected_level = if level == "all" or Enum.any?(@levels, &(Atom.to_string(&1.key) == level)), do: level, else: "all"
    {:noreply, assign(socket, :selected_level, selected_level)}
  end

  defp level_label(:beginner), do: "Beginner"
  defp level_label(:intermediate), do: "Intermediate"
  defp level_label(:advanced), do: "Advanced"

  defp level_class(:beginner), do: "bg-emerald-100 text-emerald-800"
  defp level_class(:intermediate), do: "bg-cyan-100 text-cyan-800"
  defp level_class(:advanced), do: "bg-violet-100 text-violet-800"

  defp course_cover(:rules), do: ~p"/images/poker/covers/holdem-rules.jpg"
  defp course_cover(:preflop), do: ~p"/images/poker/covers/preflop.jpg"
  defp course_cover(:equity), do: ~p"/images/poker/covers/flop.jpg"
  defp course_cover(:boards), do: ~p"/images/poker/covers/flop.jpg"
  defp course_cover(:later_streets), do: ~p"/images/poker/covers/flop.jpg"
  defp course_cover(_topic), do: ~p"/images/poker/covers/hand-reading.jpg"

  attr :module, :map, required: true

  defp module_card(assigns) do
    course = if assigns.module.course_data, do: assigns.module.course_data.data
    assigns = assign(assigns, :course, course)

    ~H"""
    <.link
      :if={@course && @module.lessons != []}
      id={"theory-module-#{@module.order}"}
      navigate={~p"/c/#{@course.slug}"}
      class="group flex min-h-64 flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:shadow-lg focus:outline-offset-4 focus:outline-2 focus:outline-indigo-500"
    >
      <img src={course_cover(@module.topic)} alt="" class="h-32 w-full object-cover" />
      <div class="flex flex-1 flex-col p-4">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-bold text-gray-900"><%= @course.name %></h3>
          <span class={["shrink-0 rounded-full px-2 py-1 text-xs font-semibold", level_class(@module.level)]}><%= level_label(@module.level) %></span>
        </div>
        <p class="mt-2 text-sm leading-5 text-gray-600"><%= @course.description %></p>
        <p class="mt-auto pt-4 text-sm font-semibold text-slate-700"><%= length(@module.lessons) %> lessons</p>
      </div>
    </.link>

    <article
      :if={!@course || @module.lessons == []}
      id={"theory-module-#{@module.order}"}
      class="min-h-64 flex flex-col overflow-hidden rounded-2xl border border-dashed border-slate-300 bg-slate-50"
    >
      <img src={course_cover(@module.topic)} alt="" class="h-32 w-full object-cover opacity-60" />
      <div class="flex flex-1 flex-col p-4">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-bold text-gray-700"><%= @module.order + 1 %>. <%= @module.name %></h3>
          <span class={["shrink-0 rounded-full px-2 py-1 text-xs font-semibold", level_class(@module.level)]}><%= level_label(@module.level) %></span>
        </div>
        <p class="mt-2 text-sm leading-5 text-gray-500"><%= if @module.lessons == [], do: "Planned", else: "Preparing lessons" %></p>
        <p class="mt-2 text-sm leading-5 text-gray-500"><%= @module.description %></p>
      </div>
    </article>
    """
  end
end
