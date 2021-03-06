defmodule M.Bot.API do
  @moduledoc false

  @behaviour M.Bot.Adapter
  @finch M.Finch

  @impl true
  def set_webhook(url) do
    request("setWebhook", %{"url" => url})
  end

  def get_webhook_info do
    request("getWebhookInfo", %{})
  end

  @impl true
  # https://core.telegram.org/bots/api#sendmessage
  def send_message(chat_id, text, opts) do
    payload = Enum.into(opts, %{"chat_id" => chat_id, "text" => text})
    request("sendMessage", payload)
  end

  @impl true
  # https://core.telegram.org/bots/api#senddocument
  def send_document(chat_id, content, filename, content_type, opts) do
    payload = Enum.into(opts, %{"chat_id" => chat_id})
    boundary = Base.url_encode64(:crypto.strong_rand_bytes(9))

    form =
      Enum.reduce(payload, [], fn {k, v}, acc ->
        [
          "--",
          boundary,
          "\r\ncontent-disposition: form-data; name=\"",
          to_string(k),
          "\"\r\n\r\n",
          to_string(v),
          "\r\n" | acc
        ]
      end)

    file = [
      "--",
      boundary,
      "\r\ncontent-disposition: form-data; name=\"document\"; filename=\"",
      filename,
      "\"\r\ncontent-type: ",
      content_type,
      "\r\n\r\n",
      content,
      "\r\n--",
      boundary,
      "--"
    ]

    multipart = [form | file]

    headers = [
      {"content-type", "multipart/form-data; boundary=" <> boundary}
    ]

    request("sendDocument", headers, multipart)
  end

  defp request(method, body) when is_map(body) do
    request(method, [{"content-type", "application/json"}], Jason.encode_to_iodata!(body))
  end

  defp request(method, headers, body) do
    req = Finch.build(:post, build_url(method), headers, body)
    Finch.request(req, @finch, receive_timeout: 20_000)
  end

  defp build_url(method) do
    "https://api.telegram.org/bot" <> M.Bot.token() <> "/" <> method
  end
end
