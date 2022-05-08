defmodule Dev do
  import Ecto.Query
  alias M.{Repo, Word, Sentences}

  def update_words(user_id) do
    Word
    |> select([w], w.word)
    |> where(user_id: ^user_id)
    |> Repo.all()
    |> Enum.each(fn word ->
      IO.puts(word)

      retry(fn ->
        case Sentences.fetch_dictionary_entries(word, [:longman]) do
          {:error, reason} ->
            IO.puts(word <> ": " <> reason)

          {:ok, %{longman: result}} ->
            case result do
              {:entries, nil} ->
                IO.puts("couldn't find anything for " <> word)

              {:entries, entries} ->
                Sentences.save_entries(:longman, user_id, entries)

              {:suggestions, suggestions} ->
                suggestions_cmds = Enum.map(suggestions, fn s -> "/" <> s end)

                message =
                  """
                  The word you have entered (#{word}) is not in the dictionary. Click on a spelling suggestion below or try your search again.

                  """ <> Enum.join(suggestions_cmds, "\n")

                IO.puts(message)
            end
        end
      end)
    end)
  end

  def send_csv(user_id) do
    %{longman: csv} = Sentences.all_words_csv(user_id, [:longman])
    M.Bot.post_document(113_011, csv, "all.csv", "text/csv")
  end

  def retry(fun, attempts \\ 5) when attempts > 0 do
    try do
      fun.()
    rescue
      e ->
        IO.puts("error #{e}")
        :timer.sleep(500)
        retry(fun, attempts - 1)
    end
  end

  def retry(fun, _) do
    raise "aaah ran out of attemps"
  end
end
