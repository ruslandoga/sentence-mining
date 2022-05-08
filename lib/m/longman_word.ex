defmodule M.LongmanWord do
  use Ecto.Schema

  @primary_key false
  schema "longman_words" do
    field :user_id, :integer, primary_key: true
    field :word, :string, primary_key: true
    field :pronunciation, :string, primary_key: true
    field :senses, {:array, :map}

    timestamps()
  end
end
