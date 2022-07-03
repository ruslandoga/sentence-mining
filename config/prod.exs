import Config

config :m, MWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :m, M.Bot, adapter: M.Bot.API
config :plug, init_mode: :compile
