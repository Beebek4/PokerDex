# we're running this tests separately because I didn't figure out how to get the PID of the Flame.call process:
# https://elixirforum.com/t/mocking-a-module-called-from-flame-call/65082/3
# This means we need to use :set_mox_global and it requires tests to run synchronously.
# To avoid disabling async in all our tests, I've created this test file that runs synchronously.
# If you know how to fix this, please open a PR. I'll be really grateful.
defmodule ZoonkWeb.UploadSyncTests do
  @moduledoc false
  use ZoonkWeb.ConnCase, async: false

  import Mox
  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content
  import ZoonkWeb.TestHelpers.Upload

  alias Zoonk.Accounts
  alias Zoonk.Content
  alias Zoonk.Organizations

  setup :set_mox_global
  setup :verify_on_exit!

  describe "upload sync" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "updates logo", %{conn: conn, school: school} do
      mock_storage()

      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/logo")
      assert_file_upload(lv, "school_logo")

      assert Organizations.get_school_by_slug!(school.slug).logo == uploaded_file_name()
    end

    test "updates icon", %{conn: conn, school: school} do
      mock_storage()

      {:ok, lv, _html} = live(conn, ~p"/dashboard/edit/icon")
      assert_file_upload(lv, "school_icon")

      assert Organizations.get_school_by_slug!(school.slug).icon == uploaded_file_name()
    end

    test "chooses and saves a preset avatar", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/avatar")

      assert user.avatar == nil

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("profile")|)
      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("avatar")|)
      assert has_element?(lv, ~s|button[phx-value-avatar="/images/poker/characters/hero.png"]|)
      refute has_element?(lv, "#upload-form-user_avatar")

      lv |> element(~s|button[phx-value-avatar="/images/poker/characters/hero.png"]|) |> render_click()

      assert Accounts.get_user!(user.id).avatar == "/images/poker/characters/hero.png"
      assert render(lv) =~ "Selected"
    end

    test "uploads a cover image", %{conn: conn, course: course} do
      mock_storage()

      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 2})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2")

      {:ok, updated_lv, _html} =
        lv
        |> element("a#lesson-cover-link", "Cover")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2/cover")

      assert_file_upload(updated_lv, "lesson_cover")

      assert Content.get_lesson!(lesson.id).cover == uploaded_file_name()
    end

    test "updates the cover image", %{conn: conn, school: school, course: course} do
      mock_storage()

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/edit/cover")

      assert has_element?(lv, ~s|li[aria-current="page"] a:fl-icontains("cover")|)
      assert_file_upload(lv, "course_cover")

      assert Content.get_course_by_slug!(course.slug, school.id).cover == uploaded_file_name()
    end
  end
end
