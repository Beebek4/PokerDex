# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Menu do
  @moduledoc """
  Menu components.
  """
  use Phoenix.Component

  import ZoonkWeb.Components.Icon

  @doc """
  Renders a menu item.

  ## Examples

      <.menu_item
        active={@live_action == :school_list}
        navigate={~p"/schools"}
        icon="tabler-school"
        title="Schools"
      />
  """
  attr :active, :boolean, default: false, doc: "Whether the menu is active or not."
  attr :icon, :string, default: nil, doc: "Icon displayed above the title."
  attr :title, :string, required: true, doc: "Menu title."
  attr :rest, :global, include: ~w(href method navigate)
  attr :class, :string, default: nil
  attr :icon_class, :string, default: nil
  attr :emphasis, :boolean, default: false

  def menu_item(assigns) do
    ~H"""
    <li aria-current={@active and "page"} class={@class}>
      <.link
        class={[
          "group flex gap-x-3 rounded-xl p-2.5 text-sm font-semibold leading-6 text-white transition",
          @active && "bg-[#2C1320] text-poker-gold shadow-inner hover:bg-[#2C1320] hover:text-poker-gold",
          not @active && "text-white hover:bg-white/10 hover:text-poker-gold"
        ]}
        {@rest}
      >
        <div :if={@icon} class={[@active && "text-poker-gold", not @active && "text-[#E2E6EF] group-hover:text-poker-gold"]}>
          <span :if={@icon == "poker-chips"} class="relative block h-6 w-6" aria-hidden="true">
            <span class="border-[3px] border-[#F4D36A] bg-[#A9812C] absolute top-1 left-0 h-5 w-5 rounded-full border-dashed shadow-sm"></span>
            <span class="border-[3px] border-[#FFF0B4] bg-[#D8B45A] absolute top-0 right-0 h-5 w-5 rounded-full border-dashed shadow-sm">
              <span class="inset-[3px] border-[#A9812C]/70 absolute rounded-full border"></span>
            </span>
          </span>
          <.icon :if={@icon != "poker-chips"} name={@icon} class={["h-6 w-6", @icon_class]} aria-hidden="true" />
        </div>

        <span
          :if={is_nil(@icon)}
          class="text-[0.625rem] border-white/30 bg-white/10 flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border font-medium text-white group-hover:border-poker-gold group-hover:text-poker-gold"
        >
          <%= String.first(@title) %>
        </span>

        <span :if={@emphasis} class="font-extrabold"><%= @title %></span>
        <%= if @emphasis, do: nil, else: @title %>
      </.link>
    </li>
    """
  end
end
