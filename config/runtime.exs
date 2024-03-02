import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

config :logger, :console, format: "$time [$level] $message\n"

config :sentry,
  environment_name: config_env()

jmdict_db_path =
  System.get_env("JMDICT_DB_PATH") || Path.expand("../jmdict.db", Path.dirname(__ENV__.file))

if File.exists?(jmdict_db_path) do
  config :m, M.JMDictRepo,
    database: jmdict_db_path,
    pool_size: String.to_integer(System.get_env("JMDICT_POOL_SIZE") || "5"),
    cache_size: -2000
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/m start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") || System.get_env("RELEASE_NAME") do
  config :m, MWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :logger, level: :info
  config :logger, backends: [:console, Sentry.LoggerBackend]

  config :sentry, dsn: System.fetch_env!("SENTRY_DSN")

  config :m, M.Bot, token: System.fetch_env!("TG_BOT_KEY")

  config :m, M.Repo,
    database: System.get_env("DB_PATH") || "m_prod.db",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    # https://litestream.io/tips/#disable-autocheckpoints-for-high-write-load-servers
    wal_auto_check_point: 0,
    # https://litestream.io/tips/#busy-timeout
    busy_timeout: 5000,
    cache_size: -2000,
    migrate: true

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.fetch_env!("PHX_HOST")
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :m, MWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end

if config_env() == :dev do
  config :logger, :console, format: "[$level] $message\n"
  config :m, M.Bot, token: System.fetch_env!("TG_BOT_KEY")
  config :m, MWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: 4000]

  config :m, M.Repo,
    database: Path.expand("../m_dev.db", Path.dirname(__ENV__.file)),
    show_sensitive_data_on_connection_error: true
end

if config_env() == :test do
  config :logger, level: :warning
  config :m, M.Repo, database: :memory
  config :m, MWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: 4002]
end
