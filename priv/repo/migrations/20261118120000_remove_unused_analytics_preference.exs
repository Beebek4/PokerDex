defmodule Zoonk.Repo.Migrations.RemoveUnusedAnalyticsPreference do
  use Ecto.Migration

  def up do
    alter table(:school_users) do
      remove :analytics?
    end
  end

  def down do
    alter table(:school_users) do
      add :analytics?, :boolean, default: true, null: false
    end
  end
end
