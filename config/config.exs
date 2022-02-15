import Config

config :m, ecto_repos: [M.Repo]

config :sentry, client: M.Sentry.FinchHTTPClient

config :sentry,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

import_config "#{config_env()}.exs"
