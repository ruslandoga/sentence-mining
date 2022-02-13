defmodule MWeb.Endpoint do
  use Plug.Router, init_mode: Application.fetch_env!(:plug, :init_mode)
  use Plug.ErrorHandler

  plug Plug.Telemetry, event_prefix: [:web]
  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :dispatch

  post "/api/bot/:token" do
    alias M.Bot

    if Bot.token() == token do
      Bot.handle(conn.body_params)
    end

    send_resp(conn, 200, [])
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
