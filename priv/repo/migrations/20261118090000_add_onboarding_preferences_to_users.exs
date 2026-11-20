defmodule Zoonk.Repo.Migrations.AddOnboardingPreferencesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :experience_level, :string
      add :learning_goal, :string
    end
  end
end
