defmodule M.Repo.Migrations.AddWords do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:words, primary_key: false) do
      add :user_id, :integer, null: false, primary_key: true
      add :word, :text, null: false, primary_key: true
      add :pronunciation, :text, null: false, primary_key: true
      add :senses, :json, null: false
      timestamps()
    end

    # TODO index on updated_at?
  end
end
