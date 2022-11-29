defmodule M.Sentences do
  alias M.{Longman, Britannica}

  @type examples :: [String.t()]
  @type definition :: String.t()
  @type word :: String.t()
  @type pronunciation :: String.t()
  @type entries :: %{{word, pronunciation} => [map]}
  @type source :: :longman | :britannica

  def recent_words_csv_stream(user_id, sources) do
    pmap(sources, :recent_words_csv_stream, [user_id])
  end

  def all_words_csv_stream(user_id, sources) do
    pmap(sources, :all_words_csv_stream, [user_id])
  end

  def count_words(user_id, sources) do
    pmap(sources, :count_words, [user_id])
  end

  # `got` doesn't work
  # `mother` missing definitions
  # jumper cables
  # cars
  @spec fetch_dictionary_entries(String.t(), [source]) ::
          {:error, String.t()}
          | {:ok,
             %{
               source =>
                 {:entries, entries}
                 | {:suggestions, [String.t()]}
                 | {:error, String.t()}
             }}
  def fetch_dictionary_entries(query, sources) do
    case String.trim(query) do
      "" ->
        {:error, "invalid request"}

      query ->
        query = URI.encode(query)
        {:ok, pmap(sources, :fetch, [query])}
    end
  end

  def save_entries(source, user_id, entries) do
    handler(source).save_entries(user_id, entries)
  end

  def dump_to_csv_stream(source, entries, opts) do
    handler(source).dump_to_csv_stream(entries, opts)
  end

  @spec handler(source) :: module
  defp handler(:longman), do: Longman
  defp handler(:britannica), do: Britannica

  defp pmap(sources, f, a) do
    sources
    |> Enum.map(fn source -> {source, Task.async(handler(source), f, a)} end)
    |> Map.new(fn {source, task} -> {source, Task.await(task)} end)
  end
end
