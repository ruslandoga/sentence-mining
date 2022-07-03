import Config

config :m, M.Repo,
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :m, MWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "oqVCSPk5goT69U3PIIiuHCLsrh6xwchcmLlw82d8OQhRsaOWU87bEEONUPmKXEGm",
  watchers: [
    npm: ["run", "watch:js", cd: Path.expand("../assets", __DIR__)],
    npm: ["run", "watch:css", cd: Path.expand("../assets", __DIR__)]
  ]

config :m, MWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/m_web/(live|views)/.*(ex)$",
      ~r"lib/m_web/templates/.*(eex)$"
    ]
  ]

config :m, M.Bot, adapter: M.Bot.API

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
