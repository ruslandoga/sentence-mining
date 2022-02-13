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

  # TODO what if exact match not found?
  # TODO what if more than one entry
  def get_sentences(word) do
    req = Finch.build(:get, "https://learnersdictionary.com/definition/" <> word)
    {:ok, %Finch.Response{body: body}} = Finch.request(req, @finch)
    html = Floki.parse_document!(body)

    # TODO
    entry = hd(Floki.find(html, ".entry"))

    pronunciation =
      entry
      |> Floki.find(".hw_txt ~ .hpron_word")
      |> Floki.text()
      |> String.replace_leading("/", "[")
      |> String.replace_trailing("/", "]")

    senses =
      entry
      |> Floki.find(".sblocks")
      |> Floki.find(".sblock")
      |> Floki.find(".sense")
      |> Enum.map(fn sense ->
        definition = sense |> Floki.find(".def_text") |> Floki.text()
        examples = sense |> Floki.find(".vi") |> Enum.map(fn vi -> Floki.text(vi) end)
        %{"definition" => definition, "examples" => examples}
      end)

    %{"pronunciation" => pronunciation, "senses" => senses}
  end

  defp dump_to_rows(word, info) do
    %{"pronunciation" => pronunciation, "senses" => senses} = info

    senses
    |> Enum.flat_map(fn sense ->
      %{"definition" => definition, "examples" => examples} = sense

      Enum.map(examples, fn example ->
        [example, word, pronunciation, definition]
      end)
    end)
  end

  def dump_to_csv(word, info) do
    word |> dump_to_rows(info) |> CSV.dump_to_iodata()
  end

  def dump_to_csv_stream(word, info) do
    word |> dump_to_csv(info) |> CSV.dump_to_stream()
  end

  def save_word_info(user_id, word, info) do
    Repo.insert(%Word{user_id: user_id, word: word, info: info},
      on_conflict: {:replace, [:info, :updated_at]},
      conflict_target: [:user_id, :word]
    )
  end

  def all_word_infos(user_id) do
    Word
    |> where(user_id: ^user_id)
    |> select([w], map(w, [:word, :info]))
    |> Repo.all()
  end

  # TODO proper localization
  def today_word_infos(user_id, reference \\ DateTime.utc_now()) do
    day_ago = DateTime.add(reference, -24 * 3600)

    Word
    |> where(user_id: ^user_id)
    |> where([w], w.updated_at >= ^day_ago)
    |> select([w], map(w, [:word, :info]))
    |> Repo.all()
  end
end
