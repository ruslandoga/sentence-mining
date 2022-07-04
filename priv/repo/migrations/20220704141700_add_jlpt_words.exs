defmodule M.Repo.Migrations.AddJlptWords do
  use Ecto.Migration

  def change do
    # TODO without rowid?
    create table(:jlpt_words, primary_key: false, options: "STRICT") do
      add :expression, :text, primary_key: true
      add :level, :integer, null: false
      add :reading, :text, null: false
      add :meaning, :text, null: false
      add :tags, :text, null: false
    end
  end
end
