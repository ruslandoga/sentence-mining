defmodule Dev do
  import Ecto.Query
  alias M.{Repo, Word, Sentences}
  require Logger

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

  def retry(fun, attempts \\ 5)

  def retry(fun, attempts) when attempts > 0 do
    try do
      fun.()
    rescue
      e ->
        IO.puts("error #{e}")
        :timer.sleep(500)
        retry(fun, attempts - 1)
    end
  end

  def retry(_, _) do
    raise "aaah ran out of attemps"
  end

  defmodule Kanji do
    use Ecto.Schema

    @primary_key false
    schema "kanji_dict" do
      field :frequency, :integer
      field :jlpt, :integer
      field :jlpt_full, :string
      field :kanji, :string
      field :radical, :string
      field :radvar, :string
      field :phonetic, :string
      field :idc, :string
      field :compact_meaning, :string
      field :meaning, :string
      field :reg_on, :string
      field :reg_kun, :string
      field :onyomi, :string
      field :kunyomi, :string
      field :nanori, :string
      field :strokes, :integer
      field :type, :string
      field :grade, :string
      field :kanken, :string
      field :rtk1_3_new, :integer
      field :ko2001, :integer
      field :ko2301, :integer
      field :wrp_jkf, :integer
      field :wanikani, :integer
    end
  end

  def load_kanjidict(path \\ Path.expand("~/Downloads/kanjidict.csv")) do
    {count, _} = Repo.delete_all(Kanji)
    Logger.debug("deleted #{count} from kanji dict")

    [headers | rows] =
      File.read!(path)
      |> NimbleCSV.RFC4180.parse_string(skip_headers: false)

    headers =
      Enum.map(headers, fn
        "jlpt " -> :jlpt
        "jlpt" -> :jlpt_full
        "phonetic ♪♫" -> :phonetic
        header -> String.to_atom(header)
      end)

    rows
    |> Enum.map(fn row ->
      row =
        Enum.map(row, fn val ->
          val = String.trim(val)
          unless val == "", do: val
        end)

      headers
      |> Enum.zip(row)
      |> Enum.map(fn
        {k, v}
        when k in [
               :frequency,
               :jlpt,
               :strokes,
               :rtk1_3_new,
               :ko2001,
               :ko2301,
               :wrp_jkf,
               :wanikani
             ] ->
          {k, if(v, do: String.to_integer(v))}

        other ->
          other
      end)
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      {count, _} = Repo.insert_all(Kanji, chunk)
      Logger.debug("inserted #{count} into kanji dict")
    end)
  end
end
