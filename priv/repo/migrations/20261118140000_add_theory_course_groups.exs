defmodule Zoonk.Repo.Migrations.AddTheoryCourseGroups do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add :curriculum_stage, :string
      add :curriculum_street, :string
    end
  end
end
