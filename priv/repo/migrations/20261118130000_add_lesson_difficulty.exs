defmodule Zoonk.Repo.Migrations.AddLessonDifficulty do
  use Ecto.Migration

  def change do
    alter table(:lessons) do
      add :difficulty, :string, default: "beginner", null: false
    end
  end
end
