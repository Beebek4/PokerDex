defmodule ZoonkWeb.Controller.HomeHTML do
  use ZoonkWeb, :html

  import ZoonkWeb.Layouts.MenuUtils, only: [school_logo: 2]

  embed_templates "templates/*"
end
