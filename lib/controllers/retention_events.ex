defmodule ZoonkWeb.Controller.RetentionEvents do
  @moduledoc false
  use ZoonkWeb, :controller

  alias Zoonk.Retention

  def create(%{assigns: %{current_user: nil}} = conn, _params) do
    conn |> put_status(:unauthorized) |> json(%{error: "authentication_required"})
  end

  def create(conn, %{"events" => events}) when is_list(events) do
    case Retention.track_batch(conn.assigns.current_user, events) do
      {:ok, count} -> json(conn, %{accepted: count})
      {:error, :consent_required} -> conn |> put_status(:forbidden) |> json(%{error: "consent_required"})
      {:error, :analytics_unavailable} -> conn |> put_status(:service_unavailable) |> json(%{error: "analytics_unavailable"})
      {:error, :batch_too_large} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "batch_too_large"})
      {:error, _reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_events"})
    end
  end

  def create(conn, _params) do
    conn |> put_status(:unprocessable_entity) |> json(%{error: "events_required"})
  end
end
