defmodule M.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    endpoint_config = Application.fetch_env!(:m, MWeb.Endpoint)
    http = Keyword.fetch!(endpoint_config, :http)

    children = [
      {Finch, name: M.Finch, pools: %{"https://api.telegram.org" => [protocol: :http2]}},
      M.Repo,
      MWeb.Telemetry,
      if endpoint_config[:server] do
        {Plug.Cowboy, scheme: :http, plug: MWeb.Endpoint, options: http}
      end
    ]

    children = Enum.reject(children, &is_nil/1)
    Supervisor.start_link(children, strategy: :one_for_one, name: M.Supervisor)
  end
end
