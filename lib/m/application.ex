defmodule M.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: M.Finch, pools: %{"https://api.telegram.org" => [protocol: :http2]}},
      M.Repo,
      MWeb.Telemetry,
      maybe_server()
    ]

    children = Enum.reject(children, &is_nil/1)
    Supervisor.start_link(children, strategy: :one_for_one, name: M.Supervisor)
  end

  @app :m

  defp maybe_server do
    config = Application.fetch_env!(@app, MWeb.Endpoint)

    if config[:server] do
      {Plug.Cowboy, scheme: :http, plug: MWeb.Endpoint, options: Keyword.fetch!(config, :http)}
    end
  end
end
