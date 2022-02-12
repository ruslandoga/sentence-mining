import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :m, MWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :m, M.Bot, token: System.fetch_env!("TG_BOT_KEY")

  config :m, M.Repo,
    database: "m_prod.db",
    show_sensitive_data_on_connection_error: true

  secret_key_base = System.fetch_env!("SECRET_KEY_BASE")

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :m, MWeb.Endpoint,
    url: [host: host, port: 443],
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
  config :m, M.Bot, token: System.fetch_env!("TG_BOT_KEY")

  config :m, M.Repo,
    database: "m_dev.db",
    show_sensitive_data_on_connection_error: true
end
