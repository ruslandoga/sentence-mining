defmodule M.Repo.Migrations.AddKanjiIdx do
  use Ecto.Migration

  def change do
    create index(:kanji_dict, [:reg_kun], where: "reg_kun is not null")
    create index(:kanji_dict, [:reg_on], where: "reg_on is not null")
    create index(:kanji_dict, [:radical], where: "radical is not null")
    create index(:kanji_dict, [:phonetic], where: "phonetic is not null")
  end
end
