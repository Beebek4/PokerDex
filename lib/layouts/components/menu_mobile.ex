# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ZoonkWeb.Components.Layouts.MenuMobile do
  @moduledoc false
  use ZoonkWeb, :html

  import ZoonkWeb.Layouts.MenuUtils

  def menu_mobile(assigns) do
    ~H"""
    <.drawer id="mobile-menu">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-white px-6 pb-4">
        <div class="flex h-16 shrink-0 items-center">
          <.link class="block aspect-[9/2] w-full overflow-hidden" navigate={~p"/home"} aria-label={"#{school_name(@school)} home"}>
            <img class="h-full w-full object-cover object-center" src={school_logo(@school, @app)} alt={school_name(@school)} />
          </.link>
        </div>

        <%= render_slot(@inner_block) %>
      </div>
    </.drawer>
    """
  end
end
