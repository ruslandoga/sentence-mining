import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

config :logger, :console, format: "$time [$level] $message\n"

config :sentry,
  environment_name: config_env(),
  included_environments: [:prod]

if System.get_env("WEB") || System.get_env("RELEASE_NAME") do
  config :m, MWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :logger, level: :info
  config :logger, backends: [:console, Sentry.LoggerBackend]

  config :sentry, dsn: System.fetch_env!("SENTRY_DSN")

  config :m, M.Bot, token: System.fetch_env!("TG_BOT_KEY")

  config :m, M.Repo,
    database: System.get_env("DB_PATH") || "m_prod.db",
    # https://litestream.io/tips/#disable-autocheckpoints-for-high-write-load-servers
    wal_auto_check_point: 0,
    # https://litestream.io/tips/#busy-timeout
    busy_timeout: 5000,
    cache_size: -1000

  port = String.to_integer(System.get_env("PORT") || "4000")

  config :m, MWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ]
end

if config_env() == :dev do
  config :logger, :console, format: "[$level] $message\n"
  config :m, M.Bot, token: System.fetch_env!("TG_BOT_KEY")
  config :m, MWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: 4000]

  config :m, M.Repo,
    database: "m_dev.db",
    show_sensitive_data_on_connection_error: true
end

if config_env() == :test do
  config :logger, level: :warn
  config :m, M.Repo, database: :memory
  config :m, MWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: 4002]
end
