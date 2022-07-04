defmodule M.Kanjis do
  import Ecto.Query
  alias M.Repo

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
      field :compact_meaning, :string
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

  def fetch_kanjis_for_kun(kun) do
    with_bracket = kun <> "（%"

    Kanji
    |> join(:inner, [k], j in fragment("json_each(?)", k.reg_kun),
      on: j.value == ^kun or like(j.value, ^with_bracket) or j.value == ^star(kun)
    )
    |> where([k], not is_nil(k.jlpt_full))
    |> Repo.all()
  end

  def fetch_kanjis_for_on(on) do
    Kanji
    |> join(:inner, [k], j in fragment("json_each(?)", k.reg_on),
      on: j.value == ^on or j.value == ^star(on)
    )
    |> where([k], not is_nil(k.jlpt_full))
    |> Repo.all()
  end

  defp star(value) do
    if String.ends_with?(value, "*") do
      String.trim_trailing(value, "*")
    else
      value <> "*"
    end
  end
end
