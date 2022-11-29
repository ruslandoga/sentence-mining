defmodule M.Bot do
  alias M.{Sentences, Longman, Britannica}
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

  def post_document(chat_id, stream, filename, content_type, opts \\ []) do
    @adapter.send_document(chat_id, Stream.chunk_every(stream, 30), filename, content_type, opts)
  end

  def handle(%{
        "message" => %{
          "text" => text,
          "chat" => %{"id" => chat_id},
          "from" => %{"id" => from_id}
        }
      }) do
    handle_text(text, %{chat_id: chat_id, from_id: from_id})
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
    longman_today = Longman.recent_words_csv_stream(from_id)
    britannica_today = Britannica.recent_words_csv_stream(from_id)
    # TODO send both at the same time
    post_document(chat_id, longman_today, "longman_today.csv", "text/csv")
    post_document(chat_id, britannica_today, "britannica_today.csv", "text/csv")
  end

  defp handle_text("/all" <> _rest, %{chat_id: chat_id, from_id: from_id}) do
    longman_all = Longman.all_words_csv_stream(from_id)
    britannica_all = Britannica.all_words_csv_stream(from_id)
    # TODO send both at the same time
    post_document(chat_id, longman_all, "longman_all.csv", "text/csv")
    post_document(chat_id, britannica_all, "britannica_all.csv", "text/csv")
  end

  defp handle_text("/count" <> _rest, %{chat_id: chat_id, from_id: from_id}) do
    counts = Sentences.count_words(from_id, [:britannica, :longman])

    message = """
    You have #{counts.britannica} words from britannica
    You have #{counts.longman} words from longman
    """

    post_message(chat_id, message)
  end

  defp handle_text("/britannica_" <> word, opts) do
    handle_word(word, opts, [:britannica])
  end

  defp handle_text("/longman_" <> word, opts) do
    handle_word(word, opts, [:longman])
  end

  defp handle_text("/" <> word, opts) do
    handle_word(word, opts, [:britannica, :longman])
  end

  defp handle_text(word, opts) do
    handle_word(word, opts, [:britannica, :longman])
  end

  defp handle_word(word, %{chat_id: chat_id, from_id: from_id}, sources) do
    for word <- String.split(word, ["\n", ","], trim: true) do
      word = word |> String.replace("__", "-") |> String.replace("_", " ")

      case Sentences.fetch_dictionary_entries(word, sources) do
        {:error, reason} ->
          post_message(chat_id, word <> ": " <> reason)

        {:ok, results} ->
          for {source, result} <- results do
            case result do
              {:entries, nil} ->
                post_message(chat_id, "couldn't find anything for #{word} in #{source}")

              {:entries, entries} ->
                Sentences.save_entries(source, from_id, entries)
                csv_stream = Sentences.dump_to_csv_stream(source, entries, first: false)
                post_document(chat_id, csv_stream, "#{source}_#{word}.csv", "text/csv")

              {:suggestions, suggestions} ->
                suggestions_cmds =
                  Enum.map(suggestions, fn suggestion ->
                    suggestion =
                      suggestion |> String.replace("-", "__") |> String.replace(" ", "_")

                    "/#{source}_#{suggestion}"
                  end)

                message =
                  """
                  The word you have entered (#{word}) is not in the #{source} dictionary. Click on a spelling suggestion below or try your search again.

                  """ <> Enum.join(suggestions_cmds, "\n")

                post_message(chat_id, message)

              {:error, reason} ->
                post_message(chat_id, word <> " (" <> to_string(source) <> "): " <> reason)
            end
          end
      end
    end
  end
end
