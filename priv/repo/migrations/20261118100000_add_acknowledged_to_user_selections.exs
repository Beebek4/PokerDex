defmodule Zoonk.Repo.Migrations.AddAcknowledgedToUserSelections do
  use Ecto.Migration

  def change do
    alter table(:user_selections) do
      add :acknowledged?, :boolean, default: true, null: false
    end
  end
end
