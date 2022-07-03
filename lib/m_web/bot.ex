defmodule MWeb.Bot do
  @moduledoc "Helpers to interact with Telegram bot."
  alias M.Bot

  # TODO
  def webhook_url(host) do
    Path.join([host, "/api/bot", Bot.token()])
  end

  def set_webhook(host) do
    Bot.set_webhook(webhook_url(host))
  end
end
