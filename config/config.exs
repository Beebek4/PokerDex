# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :esbuild,
  version: "0.21.5",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/audios/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :tailwind,
  version: "3.4.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),

    # Configure esbuild (the version is required)
    cd: Path.expand("../assets", __DIR__)
  ]

config :zoonk, Oban,
  engine: Oban.Engines.Basic,
  repo: Zoonk.Repo,
  queues: [default: 10],
  shutdown_grace_period: :timer.seconds(60),
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)}
  ]

config :zoonk, Zoonk.Mailer, adapter: Swoosh.Adapters.Local

config :zoonk, Zoonk.Poker.Native,
  crate: :poker_native,
  path: "native/poker_native"

config :zoonk, ZoonkWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ZoonkWeb.ErrorHTML, json: ZoonkWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Zoonk.PubSub,
  live_view: [signing_salt: "18a5Hr6d"]

config :zoonk, ZoonkWeb.Gettext, default_locale: "en", locales: ~w(de en pt zh_TW)
config :zoonk, :app_env, config_env()
config :zoonk, :app_env, config_env()

# Configures Elixir's Logger

# Use Jason for JSON parsing in Phoenix

# Configure tailwind (the version is required)

# Oban config
# Delete jobs after 7 days
# Automatically move failed jobs back to available so they can run again

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.

# Configures the endpoint

# Configure translation

# Content security policy
config :zoonk, :csp, connect_src: System.get_env("CSP_CONNECT_SRC")

# Storage config
config :zoonk, :storage,
  bucket: System.get_env("BUCKET_NAME"),
  domain: System.get_env("AWS_CDN_URL") || System.get_env("AWS_ENDPOINT_URL_S3")

config :zoonk,
  ecto_repos: [Zoonk.Repo],
  generators: [timestamp_type: :utc_datetime_usec],
  play_preview_all_opponents: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
