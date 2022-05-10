defmodule Dev do
  # import Ecto.Query
  # alias M.{Repo, Word, Sentences}

  # def update_words(user_id) do
  #   Word
  #   |> select([w], w.word)
  #   |> where(user_id: ^user_id)
  #   |> Repo.all()
  #   |> Enum.each(fn word ->
  #     case Sentences.fetch_dictionary_entries(word) do
  #       {:entries, nil} ->
  #         IO.puts("couldn't find anything for " <> word)

  #       {:entries, entries} ->
  #         Sentences.save_entries(user_id, entries)

  #       {:suggestions, suggestions} ->
  #         suggestions_cmds = Enum.map(suggestions, fn s -> "/" <> s end)

  #         message =
  #           """
  #           The word you have entered (#{word}) is not in the dictionary. Click on a spelling suggestion below or try your search again.

  #           """ <> Enum.join(suggestions_cmds, "\n")

  #         IO.puts(message)

  #       {:error, reason} ->
  #         IO.puts(word <> ": " <> reason)
  #     end
  #   end)
  # end

  # def send_csv(user_id) do
  #   csv = Sentences.all_words_csv(user_id)
  #   M.Bot.post_document(113_011, csv, "all.csv", "text/csv")
  # end

  def run do
    req = Finch.build(:get, "https://jlptgrammarlist.neocities.org")
    {:ok, %Finch.Response{status: 200, body: html}} = Finch.request(req, M.Finch)
    html = Floki.parse_document!(html)

    list =
      html
      |> Floki.find(".grammar-list")
      |> Enum.map(fn grammar_list ->
        {"div", [{"class", "grammar-list " <> level}], _children} = grammar_list

        grammar =
          grammar_list
          |> Floki.find(".item")
          |> Enum.reduce([], fn item, acc ->
            english_meaning = item |> Floki.find(".english-meaning") |> Floki.text()
            term_jp = item |> Floki.find(".term") |> Floki.text()

            term_en =
              case item do
                {_, _, [_, _, term_en | _]} when is_binary(term_en) -> term_en
                _other -> nil
              end

            ja_sentence = Floki.find(item, ".japanese-sentence")
            audio = ja_sentence |> Floki.find("a") |> Floki.attribute("href") |> List.first()
            ja_sentence = Floki.text(ja_sentence)
            [[ja_sentence, audio, english_meaning, term_jp, term_en] | acc]
          end)

        {level, grammar}
      end)

    for {level, list} <- list do
      csv = NimbleCSV.RFC4180.dump_to_iodata(list)
      File.write!("priv/#{level}.csv", csv)
    end
  end
end
