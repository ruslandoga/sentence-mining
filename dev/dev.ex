defmodule Dev do
  import Ecto.Query
  alias M.{Repo, Word, Sentences}

  def update_words(user_id) do
    Word
    |> select([w], w.word)
    |> where(user_id: ^user_id)
    |> Repo.all()
    |> Enum.each(fn word ->
      case Sentences.fetch_dictionary_entries(word) do
        {:entries, nil} ->
          IO.puts("couldn't find anything for " <> word)

        {:entries, entries} ->
          Sentences.save_entries(user_id, entries)

        {:suggestions, suggestions} ->
          suggestions_cmds = Enum.map(suggestions, fn s -> "/" <> s end)

          message =
            """
            The word you have entered (#{word}) is not in the dictionary. Click on a spelling suggestion below or try your search again.

            """ <> Enum.join(suggestions_cmds, "\n")

          IO.puts(message)

        {:error, reason} ->
          IO.puts(word <> ": " <> reason)
      end
    end)
  end

  def send_csv(user_id) do
    csv = Sentences.all_words_csv(user_id)
    M.Bot.post_document(113_011, csv, "all.csv", "text/csv")
  end
end
