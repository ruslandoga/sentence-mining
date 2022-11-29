defmodule M.Britannica do
  @moduledoc false
  @finch M.Finch
  @behaviour M.Handler

  import Ecto.Query
  alias NimbleCSV.RFC4180, as: CSV
  alias M.{Repo, Word}

  @impl true
  def fetch(query) do
    http_get(Path.join("dictionary", query))
  end

  @impl true
  def count_words(user_id) do
    Word
    |> where(user_id: ^user_id)
    |> select([w], fragment("count(distinct word)"))
    |> Repo.one()
  end

  @impl true
  def all_words_csv_stream(user_id) do
    Word
    |> where(user_id: ^user_id)
    |> select([w], {{w.word, w.pronunciation}, w.senses, w.inserted_at})
    |> Repo.stream(max_rows: 30)
    |> dump_to_csv_stream()
  end

  # TODO proper localization
  @impl true
  def recent_words_csv_stream(user_id, reference \\ DateTime.utc_now()) do
    day_ago = DateTime.add(reference, -24 * 3600)

    Word
    |> where(user_id: ^user_id)
    |> where([w], w.updated_at >= ^day_ago)
    |> select([w], {{w.word, w.pronunciation}, w.senses, w.inserted_at})
    |> Repo.stream(max_rows: 30)
    |> dump_to_csv_stream()
  end

  @impl true
  def dump_to_csv_stream(entries, opts \\ [first: true]) do
    CSV.dump_to_stream(to_csv_rows_stream(entries, opts))
  end

  @impl true
  def save_entries(user_id, entries) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    words =
      Enum.map(entries, fn {{word, pronunciation}, senses} ->
        %Word{
          user_id: user_id,
          word: word,
          pronunciation: pronunciation,
          senses: senses,
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.transaction(fn ->
      for word <- words do
        Repo.insert!(word,
          on_conflict: {:replace, [:senses, :updated_at]},
          conflict_target: [:user_id, :word, :pronunciation]
        )
      end
    end)

    :ok
  end

  defp to_csv_rows_stream(entries, opts) do
    Stream.flat_map(entries, &to_csv_row(&1, opts))
  end

  defp to_csv_row({{word, pronunciation}, senses}, opts) do
    Enum.reduce(senses, [], fn sense, acc ->
      %{"definition" => definition, "examples" => examples} = sense

      examples =
        if opts[:first] do
          examples |> List.first() |> List.wrap()
        else
          examples
        end

      Enum.reduce(examples, acc, fn example, acc ->
        [[example, word, pronunciation, definition] | acc]
      end)
    end)
  end

  defp to_csv_row({{word, pronunciation}, senses, inserted_at}, opts) do
    date = inserted_at |> NaiveDateTime.to_date() |> Date.to_iso8601()

    Enum.reduce(senses, [], fn sense, acc ->
      %{"definition" => definition, "examples" => examples} = sense

      examples =
        if opts[:first] do
          examples |> List.first() |> List.wrap()
        else
          examples
        end

      Enum.reduce(examples, acc, fn example, acc ->
        [[example, word, pronunciation, definition, date] | acc]
      end)
    end)
  end

  defp fetch_location(headers) do
    :proplists.get_value("location", headers, nil) || raise "failed to fetch location"
  end

  defp http_get("http" <> _ = url) do
    req = Finch.build(:get, url)

    case Finch.request(req, @finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:entries, parse_entries(body)}

      {:ok, %Finch.Response{status: 404, body: body}} ->
        {:suggestions, parse_suggestions(body)}

      {:ok, %Finch.Response{status: status, headers: headers}} when status in [301, 302] ->
        http_get(fetch_location(headers))
    end
  end

  defp http_get(path) do
    http_get(Path.join("https://www.britannica.com", path))
  end

  defp parse_suggestions(body) do
    body
    |> Floki.parse_document!()
    |> Floki.find("ul.links")
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
        |> Enum.map(fn html ->
          Floki.text(html)
          |> String.replace_leading("/", "[")
          |> String.replace_trailing("/", "]")
        end)
        |> Enum.join(" ")

      if pronunciation == "" do
        {:halt, nil}
      else
        senses =
          entry
          |> Floki.find(".sblocks")
          |> Floki.find(".sblock")
          |> Floki.find(".sense")
          |> Enum.map(fn sense ->
            definition =
              find_text(sense, ".def_text") || find_text(sense, ".un_text") ||
                sense |> find_text(".both_text") |> postprocess_both_text() ||
                sense |> find_text(".isyns") |> postprocess_isyns()

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

  @spec find_text(Floki.html_tree(), String.t()) :: String.t() | nil
  defp find_text(html, class) do
    case Floki.find(html, class) do
      [] ->
        nil

      found ->
        found
        |> Enum.map(fn html ->
          html
          |> Floki.text()
          |> String.trim()
        end)
        |> Enum.join(", ")
    end
  end

  defp postprocess_isyns(isyns) do
    if isyns do
      "= " <> String.replace(isyns, ~w[1 2 3 4 5 6 7 8 9 0], "")
    end
  end

  defp postprocess_both_text(both_text) do
    if both_text do
      both_text |> String.replace("◊", "") |> String.trim()
    end
  end
end
