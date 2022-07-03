defmodule M.Kanjis do
  import Ecto.Query
  alias M.Repo

  def fetch_kanjis_for_word(word) do
    graphemes = String.graphemes(word)

    found =
      "kanji_dict"
      |> where([k], k.kanji in ^graphemes)
      |> select(
        [k],
        map(k, [:frequency, :kanji, :radical, :phonetic, :compact_meaning, :reg_on, :reg_kun])
      )
      |> Repo.all()

    Enum.flat_map(graphemes, fn grapheme ->
      found
      |> Enum.find(fn f -> f.kanji == grapheme end)
      |> List.wrap()
    end)
  end
end
