defmodule M.Repo.Migrations.AddJlptWords do
  use Ecto.Migration

  def change do
    # TODO without rowid?
    create table(:jlpt_words, primary_key: false, options: "STRICT") do
      add :expression, :text, primary_key: true
      add :level, :integer
      add :reading, :text
      add :meaning, :text, null: false
      add :tags, :text
    end
  end
end
