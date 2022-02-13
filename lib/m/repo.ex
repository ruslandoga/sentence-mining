defmodule M.Repo do
  use Ecto.Repo, otp_app: :m, adapter: Ecto.Adapters.SQLite3
end
