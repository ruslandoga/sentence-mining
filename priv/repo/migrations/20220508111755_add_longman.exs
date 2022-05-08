defmodule M.Repo.Migrations.AddLongman do
  use Ecto.Migration

  def change do
    create table(:longman_words, primary_key: false) do
      add :user_id, :integer, null: false, primary_key: true
      add :word, :text, null: false, primary_key: true
      add :pronunciation, :text, null: false, primary_key: true
      add :senses, :json, null: false
      timestamps()
    end
  end
end
