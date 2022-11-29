defmodule M.Handler do
  @moduledoc false
  alias M.Sentences
  @callback recent_words_csv_stream(user_id :: pos_integer, (Stream.t() -> any)) :: Stream.t()
  @callback all_words_csv_stream(user_id :: pos_integer, (Stream.t() -> any)) :: Stream.t()
  @callback count_words(user_id :: pos_integer) :: non_neg_integer
  @callback fetch(query :: String.t()) :: Sentences.entries()
  @callback save_entries(user_id :: pos_integer, Sentences.entries()) :: :ok
  @callback dump_to_csv_stream(Sentences.entries(), (Stream.t() -> any), opts :: Keyword.t()) ::
              Stream.t()
end
