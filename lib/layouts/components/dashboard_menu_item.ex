# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ZoonkWeb.Components.Layouts.DashboardMenuItem do
  @moduledoc false
  use ZoonkWeb, :html

  attr :active, :boolean, default: false
  attr :rest, :global, include: ~w(href method navigate)

  slot :inner_block

  def dashboard_menu_item(assigns) do
    ~H"""
    <li aria-current={@active && "page"}>
      <.link
        class={[
          "whitespace-nowrap rounded-lg px-3 py-2 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-poker-gold",
          @active && "bg-[#2C1320] text-poker-gold hover:bg-[#2C1320] hover:text-poker-gold",
          not @active && "text-white hover:bg-white/10 hover:text-poker-gold"
        ]}
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </.link>
    </li>
    """
  end
end
