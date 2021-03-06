defmodule M.Kanjis do
  import Ecto.Query
  alias M.{Repo, JMDictRepo}

  defmodule Kanji do
    use Ecto.Schema

    @primary_key false
    schema "kanji_dict" do
      field :frequency, :integer
      field :jlpt_full, :string
      field :kanji, :string
      field :radical, :string
      field :radvar, :string
      field :phonetic, :string
      field :meaning, {:array, :string}
      field :compact_meaning, {:array, :string}
      field :reg_on, {:array, :string}
      field :reg_kun, {:array, :string}
    end
  end

  def fetch_kanjis_for_word(word) do
    graphemes = String.graphemes(word)

    found =
      Kanji
      |> where([k], k.kanji in ^graphemes)
      |> Repo.all()

    Enum.flat_map(graphemes, fn grapheme ->
      found
      |> Enum.find(fn f -> f.kanji == grapheme end)
      |> List.wrap()
    end)
  end

  def fetch_kanjis_for(filters) do
    Kanji
    |> where(^filters)
    |> where([k], not is_nil(k.jlpt_full))
    |> Repo.all()
  end

  defmacrop json_each(field) do
    quote do
      fragment("json_each(?)", unquote(field))
    end
  end

  def fetch_kanjis_for_kun(kun) do
    with_bracket = kun <> "（%"

    Kanji
    |> join(:inner, [k], j in json_each(k.reg_kun),
      on: j.value == ^kun or j.value == ^star(kun) or like(j.value, ^with_bracket)
    )
    |> where([k], not is_nil(k.jlpt_full))
    |> distinct(true)
    |> Repo.all()
  end

  def fetch_kanjis_for_on(on) do
    Kanji
    |> join(:inner, [k], j in json_each(k.reg_on), on: j.value == ^on or j.value == ^star(on))
    |> where([k], not is_nil(k.jlpt_full))
    |> distinct(true)
    |> Repo.all()
  end

  def fetch_kanjis_for_meaning(meaning) do
    Kanji
    |> join(:inner, [k], j in json_each(coalesce(k.compact_meaning, k.meaning)),
      on: j.value == ^meaning
    )
    |> where([k], not is_nil(k.jlpt_full))
    |> distinct(true)
    |> Repo.all()
  end

  defp star(value) do
    if String.ends_with?(value, "*") do
      String.trim_trailing(value, "*")
    else
      value <> "*"
    end
  end

  defmodule JLPTWord do
    use Ecto.Schema

    @primary_key false
    schema "jlpt_words" do
      field :expression, :string, primary_key: true
      field :meaning, :string
      field :reading, :string
      field :level, :integer
      field :tags, :string
    end
  end

  def jlpt_list_words do
    JLPTWord
    |> order_by([w], desc: w.level)
    |> limit(20)
    |> Repo.all()
  end

  def jlpt_get_word(word) do
    JLPTWord
    |> where(expression: ^word)
    |> Repo.one()
  end

  defmacrop json(value) do
    quote do
      fragment("json(?)", unquote(value))
    end
  end

  defmacrop json_group_array(value) do
    quote do
      fragment("json_group_array(?)", unquote(value))
    end
  end

  # https://github.com/ruslandoga/jp-sqlite
  def jmdict_get_word(word) when is_binary(word) do
    json_entries =
      "lookup"
      |> where(expression: ^word)
      |> join(:inner, [l], e in "entries", on: l.id == e.id)
      |> select([l, e], json_group_array(json(e.entry)))
      |> JMDictRepo.one()

    if json_entries do
      Jason.decode!(json_entries)
    end
  end

  def jmdict_get_words(words) when is_list(words) do
    "lookup"
    |> where([l], l.expression in ^words)
    |> join(:inner, [l], e in "entries", on: l.id == e.id)
    |> select([l, e], {l.expression, json_group_array(json(e.entry))})
    |> group_by([l], l.expression)
    |> JMDictRepo.all()
    |> Map.new(fn {_, v} = t -> put_elem(t, 1, Jason.decode!(v)) end)
  end

  # TODO use nimble_pool of ports
  def segment_sentence(sentence, opts \\ []) do
    # for now based on https://github.com/tex2e/mecab-elixir/blob/master/lib/mecab.ex
    command = """
    cat <<'EOS.907a600613b96a88c04a' | mecab
    #{sentence}
    EOS.907a600613b96a88c04a
    """

    segments =
      command
      |> to_charlist
      |> :os.cmd()
      |> to_string
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(fn line ->
        Regex.named_captures(
          ~r/
          ^
          (?<surface_form>[^\t]+)
          (?:
            \s
            (?<part_of_speech>[^,]+),
            \*?(?<part_of_speech_subcategory1>[^,]*),
            \*?(?<part_of_speech_subcategory2>[^,]*),
            \*?(?<part_of_speech_subcategory3>[^,]*),
            \*?(?<conjugation_form>[^,]*),
            \*?(?<conjugation>[^,]*),
            (?<lexical_form>[^,]*)
            (?:
              ,(?<yomi>[^,]*)
              ,(?<pronunciation>[^,]*)
            )?
          )?
          $
          /x,
          line
        )
      end)
      |> List.delete_at(-1)

    if opts[:entry] do
      words = Enum.map(segments, fn %{"lexical_form" => word} -> word end)
      jmdict_words = jmdict_get_words(words)

      Enum.map(segments, fn %{"lexical_form" => word} = segment ->
        Map.put(segment, "entry", jmdict_words[word])
      end)
    else
      segments
    end
  end
end
