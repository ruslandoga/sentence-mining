defmodule M.Bot do
  alias M.Sentences
  @adapter Application.compile_env!(:m, [__MODULE__, :adapter])

  defp config(key), do: config()[key]

  defp config do
    Application.fetch_env!(:m, __MODULE__)
  end

  def token, do: config(:token)

  def set_webhook(url) do
    @adapter.set_webhook(url)
  end

  def post_message(chat_id, text, opts \\ []) do
    @adapter.send_message(chat_id, text, opts)
  end

  def post_document(chat_id, content, filename, content_type, opts \\ []) do
    @adapter.send_document(chat_id, content, filename, content_type, opts)
  end

  def handle(%{
        "message" => %{
          "chat" => %{"id" => chat_id},
          "from" => %{"id" => from_id},
          "message_id" => message_id,
          "text" => text
        }
      }) do
    handle_text(text, %{chat_id: chat_id, from_id: from_id, message_id: message_id})
  end

  def handle(_other), do: :ok

  defp help_message do
    """
    Supported commands:

      /help
      /today
      /all
    """
  end

  defp handle_text("/help" <> _rest, %{chat_id: chat_id}) do
    post_message(chat_id, help_message())
  end

  defp handle_text("/today" <> _rest, %{chat_id: chat_id, from_id: from_id}) do
    word_infos = Sentences.today_word_infos(from_id)

    csv =
      Enum.flat_map(word_infos, fn %{word: word, info: info} ->
        Sentences.dump_to_csv(word, info)
      end)

    post_document(chat_id, csv, "all.csv", "text/csv")
  end

  defp handle_text("/all" <> _rest, %{chat_id: chat_id, from_id: from_id}) do
    word_infos = Sentences.all_word_infos(from_id)

    csv =
      Enum.flat_map(word_infos, fn %{word: word, info: info} ->
        Sentences.dump_to_csv(word, info)
      end)

    post_document(chat_id, csv, "all.csv", "text/csv")
  end

  defp handle_text("/" <> _rest, %{chat_id: chat_id}) do
    post_message(chat_id, help_message())
  end

  defp handle_text(word, %{chat_id: chat_id, from_id: from_id, message_id: _message_id}) do
    word_info = Sentences.get_sentences(word)
    {:ok, _word} = Sentences.save_word_info(from_id, word, word_info)
    # csv = Sentences.dump_to_csv(word, word_info)
    post_message(chat_id, "added #{word}")
  end
end
