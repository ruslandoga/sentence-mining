import Config

config :m, M.Repo, database: :memory

config :m, MWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6mzb/elCojaSRkbo1VEzwjuWOZnrLJdW5IGkSncNWxWvyqlTQXZlmAps0ffkl0vQ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
