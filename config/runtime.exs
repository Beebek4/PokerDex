import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/zoonk start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :zoonk, ZoonkWeb.Endpoint, server: true
end

# Remove the https:// from the beginning of the AWS_ENDPOINT_URL_S3
aws_endpoint_url = System.get_env("AWS_ENDPOINT_URL_S3")
aws_host = if aws_endpoint_url, do: String.replace(aws_endpoint_url, "https://", "")

if config_env() in [:prod, :dev] do
  config :ex_aws, :s3,
    # AWS configuration
    scheme: "https://",
    host: aws_host,
    region: System.get_env("AWS_REGION")

  config :ex_aws,
    debug_requests: config_env() == :dev,
    json_coded: Jason,
    access_key_id: {:system, "AWS_ACCESS_KEY_ID"},
    secret_access_key: {:system, "AWS_SECRET_ACCESS_KEY"}
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  configured_secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # Render's generated 256-bit base64 secrets can be shorter than Plug's
  # 64-byte minimum. Derive a stable 512-bit key so cookies remain valid
  # across restarts while preserving the generated secret's entropy.
  secret_key_base =
    if byte_size(configured_secret_key_base) >= 64 do
      configured_secret_key_base
    else
      configured_secret_key_base
      |> then(&:crypto.hash(:sha512, &1))
      |> Base.encode64(padding: false)
    end

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :zoonk, ZoonkWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :zoonk, ZoonkWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
  host =
    System.get_env("PHX_HOST") || System.get_env("RENDER_EXTERNAL_HOSTNAME") ||
      raise """
      neither PHX_HOST nor RENDER_EXTERNAL_HOSTNAME is set.
      Set PHX_HOST to the public hostname for this deployment.
      """

  port = String.to_integer(System.get_env("PORT") || "10000")
  ip = if maybe_ipv6 == [], do: {0, 0, 0, 0}, else: {0, 0, 0, 0, 0, 0, 0, 0}

  # The current free web deployment does not run background jobs. An idle
  # queue poll would prevent a free serverless Postgres database from scaling
  # down while the web app is awake.
  retention_queues = if System.get_env("KAFKA_BROKERS") in [nil, ""], do: [], else: [retention: 2]

  config :flame, :backend, FLAME.LocalBackend

  # Sentry configuration
  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    environment_name: :prod,
    enable_source_code_context: true,
    root_source_code_paths: [File.cwd!()],
    tags: %{env: :prod}

  config :zoonk, Oban, queues: retention_queues, plugins: []

  if metrics_token = System.get_env("PROMETHEUS_TOKEN") do
    config :zoonk, Zoonk.PromEx,
      metrics_server: [
        port: String.to_integer(System.get_env("PROMETHEUS_PORT") || "4021"),
        path: "/metrics",
        auth_strategy: :bearer,
        auth_token: metrics_token
      ]
  else
    config :zoonk, Zoonk.PromEx, metrics_server: []
  end

  ## Configuring the mailer
  config :zoonk, Zoonk.Mailer,
    adapter: Resend.Swoosh.Adapter,
    api_key: System.get_env("RESEND_API_KEY")

  config :zoonk, Zoonk.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    socket_options: maybe_ipv6,
    ssl: [cacerts: :public_key.cacerts_get()],
    connect_timeout: 30_000

  config :zoonk, ZoonkWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    force_ssl: [rewrite_on: [:x_forwarded_proto], hsts: true],
    check_origin: ["https://#{host}"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: ip,
      port: port
    ],
    secret_key_base: secret_key_base

  config :zoonk, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
end
