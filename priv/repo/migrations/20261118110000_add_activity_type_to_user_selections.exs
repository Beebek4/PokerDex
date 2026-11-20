defmodule Zoonk.Repo.Migrations.AddActivityTypeToUserSelections do
  use Ecto.Migration

  def change do
    alter table(:user_selections) do
      add :activity_type, :string, default: "lesson", null: false
    end
  end
end
