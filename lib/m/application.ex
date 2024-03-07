defmodule M.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    repo_config = Application.fetch_env!(:m, M.Repo)
    jmdict_repo_config = Application.fetch_env!(:m, M.JMDictRepo)

    children = [
      {Finch, name: M.Finch, pools: finch_pools()},
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

  defp finch_pools do
    pools = %{"https://api.telegram.org" => [protocols: [:http2]]}

    if sentry_dns = Application.get_env(:sentry, :dsn) do
      %URI{scheme: scheme, host: host} = URI.parse(sentry_dns)
      Map.put(pools, scheme <> "://" <> host, protocols: [:http2])
    else
      pools
    end
  end
end
