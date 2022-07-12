import Config

config :logger, level: :warn
config :m, M.Bot, adapter: M.Bot.API
config :phoenix, :plug_init_mode, :runtime

config :m, M.Repo,
  database: Path.expand("../m_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :m, M.JMDictRepo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :m, MWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "GfhL5S5PjM8RncNyv3rC/8ohyBlfyiy9pqxBDG/8XxJlIxNQ88MOZmzDjZOSrpwo",
  server: false
