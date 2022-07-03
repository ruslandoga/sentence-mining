defmodule M.Kanjis do
  import Ecto.Query
  alias M.Repo

  def fetch_kanjis_for_word(word) do
    graphemes = String.graphemes(word)

    found =
      kanji_q()
      |> where([k], k.kanji in ^graphemes)
      |> Repo.all()

    Enum.flat_map(graphemes, fn grapheme ->
      found
      |> Enum.find(fn f -> f.kanji == grapheme end)
      |> List.wrap()
    end)
  end

  # def fetch_kanjis_for_on(on) do
  #   ons =
  #     if String.ends_with?(on, "*") do
  #       [on, String.trim_trailing("*")]
  #     else
  #       [on, on <> "*"]
  #     end

  #   kanji_q()
  #   |> where([k], k.reg_on in ^ons)
  #   |> where([k], not is_nil(k.jlpt_full))
  #   |> Repo.all()
  # end

  def fetch_kanjis_for(filters) do
    kanji_q()
    |> where(^filters)
    |> where([k], not is_nil(k.jlpt_full))
    |> Repo.all()
  end

  def fetch_kanjis_like(field, pattern) do
    pattern = "%" <> pattern <> "%"

    kanji_q()
    |> where([k], like(field(k, ^field), ^pattern))
    |> where([k], not is_nil(k.jlpt_full))
    |> Repo.all()
  end

  defp kanji_q do
    "kanji_dict"
    |> select(
      [k],
      map(k, [
        :frequency,
        :jlpt_full,
        :kanji,
        :radical,
        :radvar,
        :phonetic,
        :compact_meaning,
        :reg_on,
        :reg_kun
      ])
    )
  end
end
