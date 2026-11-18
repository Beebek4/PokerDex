defmodule ZoonkWeb.Live.Play do
  @moduledoc false
  use ZoonkWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Play")}
  end
end
