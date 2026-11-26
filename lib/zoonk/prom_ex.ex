defmodule Zoonk.PromEx do
  @moduledoc false
  use PromEx, otp_app: :zoonk

  @impl PromEx
  def plugins do
    plugins = [
      PromEx.Plugins.Application,
      PromEx.Plugins.Beam,
      {PromEx.Plugins.Ecto, repos: [Zoonk.Repo]},
      {PromEx.Plugins.Phoenix, endpoint: ZoonkWeb.Endpoint, router: ZoonkWeb.Router},
      PromEx.Plugins.Broadway
    ]

    # The Oban plugin periodically queries queue state from a background
    # process. That process cannot use Ecto's per-test SQL sandbox ownership.
    # Keep queue metrics enabled in dev/prod, but avoid sandbox errors in tests.
    if Application.get_env(:zoonk, :app_env) == :test do
      plugins
    else
      plugins ++ [{PromEx.Plugins.Oban, oban_supervisors: [Oban]}]
    end
  end

  @impl PromEx
  def dashboards, do: []
end
