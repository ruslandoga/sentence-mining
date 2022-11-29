defmodule M.Longman do
  @moduledoc false
  @finch M.Finch
  @behaviour M.Handler

  import Ecto.Query
  alias NimbleCSV.RFC4180, as: CSV
  alias M.Repo
  alias M.LongmanWord, as: Word

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
  def all_words_csv_stream(user_id, f) when is_function(f, 1) do
    Repo.transaction(fn ->
      Word
      |> where(user_id: ^user_id)
      |> select([w], {{w.word, w.pronunciation}, w.senses, w.inserted_at})
      |> Repo.stream(max_rows: 30)
      |> dump_to_csv_stream()
      |> f.()
    end)
  end

  # TODO proper localization
  @impl true
  def recent_words_csv_stream(user_id, f, reference \\ DateTime.utc_now())
      when is_function(f, 1) do
    day_ago = DateTime.add(reference, -24 * 3600)

    Repo.transaction(fn ->
      Word
      |> where(user_id: ^user_id)
      |> where([w], w.updated_at >= ^day_ago)
      |> select([w], {{w.word, w.pronunciation}, w.senses, w.inserted_at})
      |> Repo.stream(max_rows: 30)
      |> dump_to_csv_stream()
      |> f.()
    end)
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
        # TODO ensure cached prepared statement
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
        %{"text" => text, "audio" => audio} = example
        [[text, render_audio(audio), word, pronunciation, definition] | acc]
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
        %{"text" => text, "audio" => audio} = example
        [[text, render_audio(audio), word, pronunciation, definition, date] | acc]
      end)
    end)
  end

  defp render_audio(url) when is_binary(url) do
    url = %URI{URI.parse(url) | query: nil}
    "[sound:#{url}]"
  end

  defp render_audio(nil), do: nil

  defp fetch_location(headers) do
    :proplists.get_value("location", headers, nil) || raise "failed to fetch location"
  end

  defp http_get(url_or_path, type \\ :entries)

  defp http_get("http" <> _ = url, type) do
    req = Finch.build(:get, url)

    case {type, Finch.request(req, @finch)} do
      {:entries, {:ok, %Finch.Response{status: 200, body: body}}} ->
        {:entries, parse_entries(body)}

      {:entries, {:ok, %Finch.Response{status: 301, headers: headers}}} ->
        http_get(fetch_location(headers), :entries)

      {:entries, {:ok, %Finch.Response{status: 302, headers: headers}}} ->
        http_get(fetch_location(headers), :suggestions)

      {:entries, {:ok, %Finch.Response{status: 404}}} ->
        {:error, "not found"}

      {:suggestions, {:ok, %Finch.Response{status: 200, body: body}}} ->
        {:suggestions, parse_suggestions(body)}
    end
  end

  defp http_get(path, type) do
    http_get(Path.join("https://www.ldoceonline.com", path), type)
  end

  defp parse_entries(body) do
    html = Floki.parse_document!(body)

    result =
      html
      |> Floki.find("span.dictentry")
      |> Enum.reduce(%{prev_pron: "", dict: %{}}, fn entry, acc ->
        %{prev_pron: prev_pron, dict: dict} = acc

        case Floki.find(entry, ".ldoceEntry") do
          [] ->
            acc

          _ ->
            word = entry |> Floki.find("span.HWD") |> Floki.text() |> String.trim()

            pronunciation =
              entry
              |> Floki.find("span.PRON")
              |> List.first()
              |> Floki.text()
              |> String.trim()
              |> case do
                "" -> prev_pron
                pron -> "[" <> pron <> "]"
              end

            senses =
              entry
              |> Floki.find("span.Sense")
              |> Enum.flat_map(fn sense ->
                subsences = Floki.find(sense, "span.Subsense")

                if Enum.empty?(subsences) do
                  [parse_sense(sense)]
                else
                  Enum.map(subsences, &parse_sense/1)
                end
              end)
              |> Enum.reject(&is_nil/1)

            %{
              prev_pron: pronunciation,
              dict: Map.update(dict, {word, pronunciation}, senses, fn prev -> senses ++ prev end)
            }
        end
      end)

    result.dict
  end

  defp parse_sense(sense) do
    definition =
      sense
      |> Floki.find("span.DEF")
      |> Enum.flat_map(&Floki.children/1)
      # workaround for two consequtive anchor tags missing space when using `Floki.text(Floki.find("span.DEF"))`
      # example: "uncontrolledflames, light, and heat that destroy and damage things"
      # at https://www.ldoceonline.com/dictionary/fire
      |> Enum.map(fn el ->
        text = [el] |> Floki.text() |> String.trim()

        if String.starts_with?(text, [",", ".", "'", ";", "?", "!"]) do
          text
        else
          " " <> text
        end
      end)
      |> Enum.join()
      |> String.trim_leading()

    unless definition == "" do
      examples =
        sense
        |> Floki.find("span.EXAMPLE")
        |> Enum.map(fn span ->
          text = span |> Floki.text() |> String.trim()

          audio =
            case Floki.find(span, "span[data-src-mp3]") do
              [{"span", _, _} = span] -> span |> Floki.attribute("data-src-mp3") |> List.first()
              [] -> nil
            end

          %{"text" => text, "audio" => audio}
        end)

      %{"definition" => definition, "examples" => examples}
    end
  end

  defp parse_suggestions(body) do
    html = Floki.parse_document!(body)

    html
    |> Floki.find("ul.didyoumean > li")
    |> Enum.map(fn list_item ->
      list_item |> Floki.text() |> String.trim()
    end)
  end
end
