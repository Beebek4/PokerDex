defmodule ZoonkWeb.Controller.Home do
  @moduledoc false
  use ZoonkWeb, :controller

  alias Zoonk.Accounts
  alias Zoonk.Organizations
  alias ZoonkWeb.Plugs.UserAuth

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{current_user: nil}} = conn, _params), do: redirect(conn, to: ~p"/welcome")
  def index(conn, _params), do: redirect(conn, to: ~p"/home")

  def welcome(%{assigns: %{current_user: user}} = conn, _params) when not is_nil(user), do: redirect(conn, to: ~p"/home")

  def welcome(conn, _params) do
    conn = assign(conn, :app, Organizations.get_app_school!(conn.assigns.school))
    conn = put_layout(conn, html: {ZoonkWeb.Layouts, :auth})
    render(conn, :welcome, csrf_token: Plug.CSRFProtection.get_csrf_token())
  end

  def start(%{assigns: %{current_user: user}} = conn, _params) when not is_nil(user), do: redirect(conn, to: ~p"/home")

  def start(%{assigns: %{school: %{allow_guests?: true}}} = conn, params) do
    learning_goal =
      case params["learning_goal"] do
        "" -> nil
        value -> value
      end

    attrs = %{
      "experience_level" => params["experience_level"],
      "learning_goal" => learning_goal
    }

    case Accounts.create_guest_user(attrs) do
      {:ok, user} -> UserAuth.log_in_user(conn, user, %{"remember_me" => "true"})
      {:error, _changeset} -> conn |> put_flash(:error, gettext("Please choose your experience level.")) |> redirect(to: ~p"/welcome")
    end
  end

  def start(conn, _params), do: conn |> put_flash(:error, gettext("Guest learning is not enabled for this school.")) |> redirect(to: ~p"/users/login")
end
