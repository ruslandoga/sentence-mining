defmodule M.Word do
  use Ecto.Schema

  @primary_key false
  schema "words" do
    field :user_id, :integer, primary_key: true
    field :word, :string, primary_key: true
    field :info, :map

    timestamps()
  end
end
