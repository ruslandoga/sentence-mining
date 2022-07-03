import Config

config :m, ecto_repos: [M.Repo]

config :m, MWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: MWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: M.PubSub,
  live_view: [signing_salt: "yePNywHX"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :sentry, client: M.Sentry.FinchHTTPClient

config :sentry,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

import_config "#{config_env()}.exs"
