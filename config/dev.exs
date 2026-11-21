import Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :phoenix_live_view,
  # Include HEEx debug annotations as HTML comments in rendered markup
  debug_heex_annotations: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Configure your database. When DATABASE_URL is present, use the Neon pooled
# connection for the long-running Phoenix server. Otherwise keep the local DB.
if database_url = System.get_env("DATABASE_URL") do
  config :zoonk, Zoonk.Repo,
    url: database_url,
    ssl: [cacerts: :public_key.cacerts_get()],
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")
else
  config :zoonk, Zoonk.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "zoonk_dev",
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10
end

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :zoonk, ZoonkWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
  https: [
    ip: {0, 0, 0, 0},
    port: 4001,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "9C1wkb+u5ctJ4kDlHzzUjUog2RA+micdmJhvxXYZp5+0CMa+7dcaoOZKltPXdd7k",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :zoonk, ZoonkWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/gettext/.*(po)$",
      ~r"lib/(.*)/.*(ex|heex)$"
    ]
  ]

config :zoonk, :play_preview_all_opponents, true

# Enable dev routes for dashboard and mailbox
config :zoonk, dev_routes: true

# Allows local visual review of every Home opponent without changing campaign progress.
