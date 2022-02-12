defmodule MWeb.Bot do
  @moduledoc "Helpers to interact with Telegram bot."

  def webhook_url do
    MWeb.Router.Helpers.bot_url(MWeb.Endpoint, :webhook, M.Bot.token())
  end

  def set_webhook do
    M.Bot.set_webhook(webhook_url())
  end
end
