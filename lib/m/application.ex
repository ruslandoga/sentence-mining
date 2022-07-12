defmodule M.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    repo_config = Application.fetch_env!(:m, M.Repo)
    jmdict_repo_config = Application.fetch_env!(:m, M.JMDictRepo)

    children = [
      {Finch, name: M.Finch, pools: %{"https://api.telegram.org" => [protocol: :http2]}},
      M.Repo,
      if database = jmdict_repo_config[:database] do
        if File.exists?(database) do
          M.JMDictRepo
        end
      end,
      {M.Release.Migrator, migrate: repo_config[:migrate]},
      MWeb.Telemetry,
      {Phoenix.PubSub, name: M.PubSub},
      MWeb.Endpoint
    ]

    children = Enum.reject(children, &is_nil/1)
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
