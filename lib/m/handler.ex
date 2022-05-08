defmodule M.Handler do
  @moduledoc false
  alias M.Sentences
  @callback recent_words_csv(user_id :: pos_integer) :: iodata
  @callback all_words_csv(user_id :: pos_integer) :: iodata
  @callback count_words(user_id :: pos_integer) :: non_neg_integer
  @callback fetch(query :: String.t()) :: Sentences.entries()
  @callback save_entries(user_id :: pos_integer, Sentences.entries()) :: :ok
  @callback dump_to_csv(Sentences.entries(), opts :: Keyword.t()) :: iodata
end
