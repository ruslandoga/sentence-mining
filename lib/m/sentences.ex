defmodule M.Sentences do
  @finch M.Finch

  alias NimbleCSV.RFC4180, as: CSV
  alias M.{Repo, Word}

  import Ecto.Query

  def get_old_sentences(word) do
    req = Finch.build(:get, "https://www.ldoceonline.com/dictionary/" <> word)
    {:ok, %Finch.Response{body: body}} = Finch.request(req, @finch)
    html = Floki.parse_document!(body)

    html
    |> Floki.find(".entry_content")
    |> Floki.find(".exa")
    |> Enum.map(fn tag -> Floki.text(tag) end)
  end

  @type examples :: [String.t()]
  @type definition :: String.t()
  @type word :: String.t()
  @type pronunciation :: String.t()
  @type entries :: %{{word, pronunciation} => [%{definition => examples}]}

  # `got` doesn't work
  # `mother` missing definitions
  # jumper cables
  @spec fetch_dictionary_entries(String.t()) ::
          {:entries, entries} | {:suggestions, [String.t()]} | {:error, String.t()}
  def fetch_dictionary_entries(query) do
    query = String.trim(query)

    case query do
      "" ->
        {:error, "invalid request"}

      _not_empty ->
        case learnersdictionary_get(Path.join("/definition/", query)) do
          {:ok, %Finch.Response{status: 200, body: body}} ->
            {:entries, parse_entries(body)}

          {:ok, %Finch.Response{status: 302, headers: headers}} ->
            "/spelling/" <> _word = location = :proplists.get_value("location", headers)

            case learnersdictionary_get(location) do
              {:ok, %Finch.Response{status: 302, headers: headers}} ->
                "/not-found" = :proplists.get_value("location", headers)
                {:error, "not found"}

              {:ok, %Finch.Response{status: 404, body: body}} ->
                {:suggestions, parse_suggestions(body)}
            end

          {:error, _} ->
            {:error, "invalid request"}
        end
    end
  end

  defp learnersdictionary_get(path) do
    req = Finch.build(:get, Path.join("https://learnersdictionary.com", path))
    Finch.request(req, @finch)
  end

  defp parse_suggestions(body) do
    body
    |> Floki.parse_document!()
    |> Floki.find(".links")
    |> Floki.find("li")
    |> Enum.map(fn li -> Floki.text(li) end)
  end

  defp parse_entries(body) do
    body
    |> Floki.parse_document!()
    |> Floki.find(".entry")
    |> Enum.reduce_while(%{}, fn entry, acc ->
      word =
        entry
        |> Floki.find(".hw_d > .hw_txt")
        |> Floki.text()
        # TODO
        |> String.replace(~w[1 2 3 4 5 6 7 8 9 0], "")
        |> String.trim()

      pronunciation =
        entry
        |> Floki.find(".hw_txt ~ .hpron_word")
        |> Floki.text()
        |> String.replace_leading("/", "[")
        |> String.replace_trailing("/", "]")

      if pronunciation == "" do
        {:halt, nil}
      else
        senses =
          entry
          |> Floki.find(".sblocks")
          |> Floki.find(".sblock")
          |> Floki.find(".sense")
          |> Enum.map(fn sense ->
            definition = sense |> Floki.find(".def_text") |> Floki.text()

            examples =
              sense
              |> Floki.find(".vi")
              |> Enum.map(fn vi -> Floki.text(vi) end)

            %{"definition" => definition, "examples" => examples}
          end)

        {:cont, Map.update(acc, {word, pronunciation}, senses, fn prev -> senses ++ prev end)}
      end
    end)
  end

  @spec to_csv_rows(entries) :: [list(String.t())]
  defp to_csv_rows(entries) do
    Enum.flat_map(entries, fn {{word, pronunciation}, senses} ->
      Enum.flat_map(senses, fn sense ->
        %{"definition" => definition, "examples" => examples} = sense

        Enum.map(examples, fn example ->
          [example, String.replace(example, word, "___"), word, pronunciation, definition]
        end)
      end)
    end)
  end

  @spec dump_to_csv(entries) :: iodata
  def dump_to_csv(entries) do
    CSV.dump_to_iodata(to_csv_rows(entries))
  end

  @spec dump_to_csv_stream(entries) :: Stream.t()
  def dump_to_csv_stream(entries) do
    CSV.dump_to_stream(to_csv_rows(entries))
  end

  @spec save_entries(pos_integer, entries) :: {non_neg_integer, nil}
  def save_entries(user_id, entries) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    to_insert =
      Enum.map(entries, fn {{word, pronunciation}, senses} ->
        %{
          user_id: user_id,
          word: word,
          pronunciation: pronunciation,
          senses: senses,
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(Word, to_insert,
      on_conflict: {:replace, [:senses, :updated_at]},
      conflict_target: [:user_id, :word, :pronunciation]
    )
  end

  def count_words(user_id) do
    words =
      Word
      |> where(user_id: ^user_id)
      |> group_by([w], w.word)

    Repo.aggregate(subquery(words), :count)
  end

  @spec all_words(pos_integer) :: [%Word{}]
  def all_words(user_id) do
    Word
    |> where(user_id: ^user_id)
    |> select([w], map(w, [:word, :pronunciation, :senses]))
    |> Repo.all()
  end

  @spec all_words_csv(pos_integer) :: iodata
  def all_words_csv(user_id) do
    Word
    |> where(user_id: ^user_id)
    |> select([w], {{w.word, w.pronunciation}, w.senses})
    |> Repo.all()
    |> dump_to_csv()
  end

  # TODO proper localization
  @spec recent_words(pos_integer, DateTime.t()) :: [%Word{}]
  def recent_words(user_id, reference \\ DateTime.utc_now()) do
    day_ago = DateTime.add(reference, -24 * 3600)

    Word
    |> where(user_id: ^user_id)
    |> where([w], w.updated_at >= ^day_ago)
    |> select([w], map(w, [:word, :pronunciation, :senses]))
    |> Repo.all()
  end

  @spec recent_words_csv(pos_integer, DateTime.t()) :: iodata
  def recent_words_csv(user_id, reference \\ DateTime.utc_now()) do
    day_ago = DateTime.add(reference, -24 * 3600)

    Word
    |> where(user_id: ^user_id)
    |> where([w], w.updated_at >= ^day_ago)
    |> select([w], {{w.word, w.pronunciation}, w.senses})
    |> Repo.all()
    |> dump_to_csv()
  end
end
