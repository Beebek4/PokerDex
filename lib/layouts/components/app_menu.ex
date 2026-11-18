# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ZoonkWeb.Components.Layouts.AppMenu do
  @moduledoc false
  use ZoonkWeb, :html

  import ZoonkWeb.Layouts.MenuUtils, only: [user_settings?: 1]

  def app_menu(assigns) do
    ~H"""
    <nav class="flex flex-1 flex-col">
      <ul role="list" class="flex flex-1 flex-col gap-y-7">
        <li>
          <ul role="list" class="-mx-2 space-y-1">
            <.menu_item navigate={~p"/play"} icon="poker-chips" emphasis active={@active_page == :play} title={gettext("Play")} />
            <.menu_item navigate={~p"/practice"} icon="tabler-cards" active={@active_page in [:practice, :review]} title={gettext("Puzzles")} />
            <.menu_item navigate={~p"/courses"} icon="tabler-book-2" active={@active_page in [:courselist, :mycourses, :courseview]} title={gettext("Theory")} />
            <.menu_item navigate={~p"/progress"} icon="tabler-chart-bar" active={@active_page == :progress} title={gettext("Progress")} />
          </ul>
        </li>

        <li class="mt-auto">
          <ul class="-mx-2 space-y-1">
            <.menu_item navigate={~p"/users/settings"} icon="tabler-user-circle" active={user_settings?(@active_page)} title={gettext("Profile")} />
          </ul>
        </li>
      </ul>
    </nav>
    """
  end
end
