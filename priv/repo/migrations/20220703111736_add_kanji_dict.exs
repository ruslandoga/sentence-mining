defmodule M.Repo.Migrations.AddKanjiDict do
  use Ecto.Migration

  def change do
    create table(:kanji_dict, primary_key: false, options: "STRICT") do
      add :frequency, :integer
      add :jlpt, :integer
      add :jlpt_full, :text
      add :kanji, :text
      add :radical, :text
      add :radvar, :text
      add :phonetic, :text
      add :idc, :text
      add :compact_meaning, :text
      add :meaning, :text
      add :reg_on, :text
      add :reg_kun, :text
      add :onyomi, :text
      add :kunyomi, :text
      add :nanori, :text
      add :strokes, :integer
      add :type, :text
      add :grade, :text
      add :kanken, :text
      add :rtk1_3_new, :integer
      add :ko2001, :integer
      add :ko2301, :integer
      add :wrp_jkf, :integer
      add :wanikani, :integer
    end

    create index(:kanji_dict, [:kanji])
  end
end
