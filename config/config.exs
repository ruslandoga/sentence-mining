import Config

config :m, ecto_repos: [M.Repo]

config :m, MWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: MWeb.ErrorHTML, json: MWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: M.PubSub,
  live_view: [signing_salt: "yePNywHX"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :sentry,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  client: M.Sentry.FinchHTTPClient

import_config "#{config_env()}.exs"
