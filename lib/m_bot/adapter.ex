defmodule M.Bot.Adapter do
  @moduledoc false
  @callback set_webhook(url :: String.t()) :: any
  @callback send_message(chat_id :: integer, text :: String.t(), opts :: Keyword.t()) :: any
  @callback send_document(
              chat_id :: integer,
              content :: iodata() | Stream.t(),
              filename :: String.t(),
              content_type :: String.t(),
              opts :: Keyword.t()
            ) :: any
end
