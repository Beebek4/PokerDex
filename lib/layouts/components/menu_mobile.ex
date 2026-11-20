# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ZoonkWeb.Components.Layouts.MenuMobile do
  @moduledoc false
  use ZoonkWeb, :html

  import ZoonkWeb.Layouts.MenuUtils

  def menu_mobile(assigns) do
    ~H"""
    <.drawer id="mobile-menu">
      <div class="bg-[#5F4B66] flex grow flex-col gap-y-5 overflow-y-auto px-6 pb-4 text-white">
        <div class="flex h-16 shrink-0 items-center">
          <.link class="flex h-full w-full min-w-0 items-center justify-start gap-3 overflow-hidden px-2" navigate={~p"/home"} aria-label={"#{school_name(@school)} home"}>
            <img class="max-w-[3.5rem] max-h-12 shrink-0 object-contain object-center" src={school_logo(@school, @app)} alt="" />
            <span class="shrink-0 text-2xl font-extrabold leading-none tracking-tight">
              <span class="text-[#18151A]">Poker</span><span class="text-[#C62828]">Dex</span>
            </span>
          </.link>
        </div>

        <%= render_slot(@inner_block) %>
      </div>
    </.drawer>
    """
  end
end
