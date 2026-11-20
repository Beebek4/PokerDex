defmodule Zoonk.Repo.Migrations.AddPokerScenarioFields do
  use Ecto.Migration

  def change do
    alter table(:lesson_steps) do
      add :poker_scenario, :map
    end

    alter table(:step_options) do
      add :score, :integer
      add :score_label, :string
    end

    alter table(:user_selections) do
      add :score, :integer
      add :scenario_version, :integer
      add :scenario_snapshot, :map
    end
  end
end
