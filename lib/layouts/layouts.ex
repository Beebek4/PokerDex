defmodule ZoonkWeb.Layouts do
  @moduledoc false
  use ZoonkWeb, :html

  import ZoonkWeb.Components.Layouts.AppMenu
  import ZoonkWeb.Components.Layouts.DashboardMenuItem
  import ZoonkWeb.Components.Layouts.MenuDesktop
  import ZoonkWeb.Components.Layouts.MenuMobile
  import ZoonkWeb.Layouts.MenuUtils

  alias Zoonk.Organizations.School
  alias ZoonkWeb.Components.Layouts.CourseSelect
  alias ZoonkWeb.Components.Layouts.LessonSelect

  embed_templates "templates/*"

  @spec social_image(String.t() | nil, School.t() | nil) :: String.t()
  def social_image(nil, school), do: school_logo(school, nil)
  def social_image(img, _school), do: img

  @spec page_title(String.t() | nil, School.t() | nil) :: String.t()
  def page_title(nil, school), do: school_name(school)
  def page_title(title, _school), do: title

  @legacy_suit_avatars [
    "/images/poker/suits/spade.png",
    "/images/poker/suits/heart.png",
    "/images/poker/suits/diamond.png",
    "/images/poker/suits/club.png"
  ]

  defp navbar_avatar(nil), do: ~p"/images/poker/characters/hero.png"

  defp navbar_avatar(avatar) when avatar in @legacy_suit_avatars, do: ~p"/images/poker/characters/hero.png"

  defp navbar_avatar(avatar), do: avatar
end
