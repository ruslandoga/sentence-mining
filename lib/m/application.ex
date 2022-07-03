defmodule M.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    repo_config = Application.fetch_env!(:m, M.Repo)

    children = [
      {Finch, name: M.Finch, pools: %{"https://api.telegram.org" => [protocol: :http2]}},
      M.Repo,
      {M.Release.Migrator, migrate: repo_config[:migrate]},
      MWeb.Telemetry,
      {Phoenix.PubSub, name: M.PubSub},
      MWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: M.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
