defmodule ZoonkWeb.Components.MetricInfo do
  @moduledoc "Accessible inline help for poker statistics."
  use Phoenix.Component

  import ZoonkWeb.Components.Icon

  attr :label, :string, required: true
  attr :description, :string, required: true
  attr :align, :atom, default: :start, values: [:start, :end]
  attr :placement, :atom, default: :below, values: [:above, :below]

  def metric_info(assigns) do
    ~H"""
    <details name="poker-metric-info" class="poker-metric-info" data-align={@align} data-placement={@placement}>
      <summary aria-label={"Explain #{@label}"} title={"Explain #{@label}"}>
        <.icon name="tabler-info-circle" class="h-3.5 w-3.5" />
      </summary>
      <span class="poker-metric-info-copy" role="note"><%= @description %></span>
    </details>
    """
  end
end
