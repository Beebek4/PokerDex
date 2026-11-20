defmodule ZoonkWeb.HomeControllerTest do
  @moduledoc false
  use ZoonkWeb.ConnCase, async: true

  import Zoonk.Fixtures.Content
  import Zoonk.Fixtures.Organizations

  alias Zoonk.Accounts

  describe "GET /welcome" do
    setup do
      set_school(%{conn: build_conn()}, allow_guests?: true)
    end

    test "shows the onboarding choices before account creation", %{conn: conn} do
      response = conn |> get(~p"/welcome") |> html_response(200)
      assert response =~ "How familiar are you with poker?"
      assert response =~ "Start learning as a guest"
      assert response =~ "fictional"
    end
  end

  describe "POST /start" do
    setup do
      set_school(%{conn: build_conn()}, %{allow_guests?: true})
    end

    test "creates a guest and saves the selected onboarding preferences", %{conn: conn} do
      conn = get(conn, ~p"/welcome")
      response = html_response(conn, 200)
      csrf_token = response |> Floki.parse_document!() |> Floki.attribute("input[name='_csrf_token']", "value") |> hd()

      conn =
        post(conn, ~p"/start", %{
          "_csrf_token" => csrf_token,
          "experience_level" => "know_rules",
          "learning_goal" => "basics"
        })

      assert redirected_to(conn) == ~p"/"
      user = conn |> get_session(:user_token) |> Accounts.get_user_by_session_token()
      assert user.guest?
      assert user.experience_level == "know_rules"
      assert user.learning_goal == "basics"
    end
  end

  describe "GET / (public school, logged in)" do
    setup :app_setup

    test "redirects to school setup when user exists but school doesn't", %{conn: conn} do
      result = conn |> Map.put(:host, "invalid.org") |> get(~p"/")
      assert redirected_to(result) == ~p"/welcome"
    end

    test "redirects to the trainer home when a user never completed a lesson", %{conn: conn} do
      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/home"
    end

    test "redirects to the trainer home when a user completed a lesson", %{conn: conn, school: school, user: user} do
      course = course_fixture(%{school: school})
      generate_user_lesson(user.id, 0, course: course)

      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/home"
    end

    test "doesn't redirect to another school's course", %{conn: conn, school: school, user: user} do
      course = course_fixture(%{school: school})

      other_school = school_fixture(%{name: "Other School"})
      other_course = course_fixture(%{school: other_school})

      generate_user_lesson(user.id, -1, course: course)
      generate_user_lesson(user.id, 0, course: other_course)

      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/home"
    end

    test "redirects to the trainer home when a user completed courses only from another school", %{conn: conn, school: school, user: user} do
      course_fixture(%{school: school})

      other_school = school_fixture(%{name: "Other School"})
      other_course = course_fixture(%{school: other_school})

      generate_user_lesson(user.id, 0, course: other_course)

      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/home"
    end
  end
end
