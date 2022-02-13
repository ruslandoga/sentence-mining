import Config

config :m, ecto_repos: [M.Repo]

import_config "#{config_env()}.exs"
