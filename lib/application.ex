defmodule Zoonk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Oban.Telemetry
  alias Zoonk.Jobs.Reporter

  @impl Application
  def start(_type, _args) do
    flame_parent = FLAME.Parent.get()
    analytics_worker? = System.get_env("RETENTION_ROLE") == "analytics"
    retention_consumer? = analytics_worker? and System.get_env("KAFKA_BROKERS") not in [nil, ""]

    Telemetry.attach_default_logger()
    Reporter.attach()

    children = [
      # Start telemetry before Repo so it observes Ecto's initialization events.
      Zoonk.PromEx,
      # Start the Telemetry supervisor
      ZoonkWeb.Telemetry,
      # Start the Ecto repository
      Zoonk.Repo,
      {Oban, Application.fetch_env!(:zoonk, Oban)},
      !flame_parent && {DNSCluster, query: Application.get_env(:zoonk, :dns_cluster_query) || :ignore},
      # Start the PubSub system
      {Phoenix.PubSub, name: Zoonk.PubSub},
      # Start the Endpoint (http/https)
      !flame_parent && !analytics_worker? && ZoonkWeb.Endpoint,
      retention_consumer? && Zoonk.Retention.Consumer,
      # Start a worker by calling: Zoonk.Worker.start_link(arg)
      # {Zoonk.Worker, arg}
      # FLAME pool
      {FLAME.Pool, name: Zoonk.FLAME.ImageOptimization, min: 0, max: 10}
    ]

    # Sentry logging
    Logger.add_backend(Sentry.LoggerBackend)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Zoonk.Supervisor]
    children |> Enum.filter(& &1) |> Supervisor.start_link(opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    ZoonkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
