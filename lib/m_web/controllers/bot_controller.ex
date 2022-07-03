defmodule MWeb.BotController do
  use MWeb, :controller

  def webhook(conn, %{"token" => token} = params) do
    alias M.Bot

    if Bot.token() == token do
      Bot.handle(params)
    end

    send_resp(conn, 200, [])
  end
end
