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
      /count
    """
  end

  defp handle_text("/help" <> _rest, %{chat_id: chat_id}) do
    post_message(chat_id, help_message())
  end

  defp handle_text("/today" <> _rest, %{chat_id: chat_id, from_id: from_id}) do
    csv = Sentences.recent_words_csv(from_id)
    post_document(chat_id, csv, "today.csv", "text/csv")
  end

  defp handle_text("/all" <> _rest, %{chat_id: chat_id, from_id: from_id}) do
    csv = Sentences.all_words_csv(from_id)
    post_document(chat_id, csv, "all.csv", "text/csv")
  end

  defp handle_text("/count" <> _rest, %{chat_id: chat_id, from_id: from_id}) do
    count = Sentences.count_words(from_id)

    message = """
    You have #{count} words
    """

    post_message(chat_id, message)
  end

  defp handle_text("/" <> word, opts) do
    handle_text(word, opts)
  end

  defp handle_text(word, %{chat_id: chat_id, from_id: from_id, message_id: _message_id}) do
    for word <- String.split(word, "\n", trim: true) do
      case Sentences.fetch_dictionary_entries(word) do
        {:entries, nil} ->
          post_message(chat_id, "couldn't find anything for " <> word)

        {:entries, entries} ->
          Sentences.save_entries(from_id, entries)
          csv = Sentences.dump_to_csv(entries)
          post_document(chat_id, csv, "#{word}.csv", "text/csv")

        {:suggestions, suggestions} ->
          suggestions_cmds = Enum.map(suggestions, fn s -> "/" <> s end)

          message =
            """
            The word you have entered (#{word}) is not in the dictionary. Click on a spelling suggestion below or try your search again.

            """ <> Enum.join(suggestions_cmds, "\n")

          post_message(chat_id, message)

        {:error, reason} ->
          post_message(chat_id, word <> ": " <> reason)
      end
    end
  end
end
