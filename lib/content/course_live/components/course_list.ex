# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Content.CourseList do
  @moduledoc false
  use ZoonkWeb, :html

  alias Zoonk.Content.CourseUtils
  alias Zoonk.Storage

  attr :id, :string, required: true
  attr :courses, :list, required: true
  attr :my_courses, :boolean, default: false
  attr :empty, :boolean, default: false

  def course_list(assigns) do
    ~H"""
    <dl
      :if={not @empty}
      id={@id}
      phx-update="stream"
      class="mt-8 grid grid-cols-1 gap-4 3xl:grid-cols-5 4xl:grid-cols-6 5xl:grid-cols-7 6xl:grid-cols-8 7xl:grid-cols-9 sm:grid-cols-2 lg:gap-6 xl:grid-cols-3 xl:gap-8 2xl:grid-cols-4"
    >
      <.link
        :for={{dom_id, course_data} <- @courses}
        id={dom_id}
        navigate={course_link(course_data, @my_courses)}
        class="group flex min-h-[15rem] flex-col overflow-hidden rounded-2xl border border-white/10 bg-[#351B2B] shadow-lg shadow-black/20 transition hover:-translate-y-0.5 hover:border-poker-gold/40 hover:shadow-xl focus:outline-offset-4 focus:outline-2 focus:outline-poker-gold"
      >
        <% course = if @my_courses, do: course_data, else: course_data.data %>
        <% cover_url = course_cover(course) %>
        <img :if={cover_url} src={cover_url} alt="" class="h-36 w-full object-cover" />

        <div class="flex min-w-0 flex-1 flex-col p-5 text-sm">
          <dt class="truncate font-bold text-white"><%= course.name %></dt>
          <dd class="line-clamp-3 text-[#A7ADC6] pt-2 text-sm leading-6"><%= course.description %></dd>

          <div class="mt-auto flex flex-wrap gap-2 pt-5">
            <.badge icon="tabler-chart-arrows-vertical"><%= course_level_label(course) %></.badge>
            <.badge :if={not @my_courses} icon="tabler-user" color={:black}><%= course_data.student_count %></.badge>
          </div>
        </div>
      </.link>
    </dl>
    """
  end

  defp course_link(course, true), do: ~p"/c/#{course.slug}"
  defp course_link(course, false), do: ~p"/c/#{course.data.slug}"

  defp course_cover(%{cover: cover}) when is_binary(cover), do: Storage.get_url(cover)
  defp course_cover(%{slug: "holdem-start-here"}), do: ~p"/images/poker/covers/holdem-rules.jpg"
  defp course_cover(%{slug: "theory-preflop-fundamentals"}), do: ~p"/images/poker/covers/preflop.jpg"
  defp course_cover(%{slug: "theory-flop-fundamentals"}), do: ~p"/images/poker/covers/flop.jpg"
  defp course_cover(%{slug: "theory-turn-fundamentals"}), do: ~p"/images/poker/covers/flop.jpg"
  defp course_cover(%{slug: "theory-river-fundamentals"}), do: ~p"/images/poker/covers/flop.jpg"
  defp course_cover(%{slug: "theory-showdown-fundamentals"}), do: ~p"/images/poker/covers/holdem-rules.jpg"
  defp course_cover(%{slug: "holdem-preflop"}), do: ~p"/images/poker/covers/preflop.jpg"
  defp course_cover(%{slug: "holdem-flop-decisions"}), do: ~p"/images/poker/covers/flop.jpg"
  defp course_cover(_course), do: nil

  defp course_level_label(%{curriculum_stage: :fundamentals}), do: "Fundamentals"
  defp course_level_label(%{curriculum_stage: :competency}), do: "Competency"
  defp course_level_label(%{curriculum_stage: :deep_dive}), do: "Deep Dive"
  defp course_level_label(%{curriculum_stage: :mastery}), do: "Mastery"
  defp course_level_label(course), do: CourseUtils.level_label(course.level)
end
