defmodule Zoonk.Repo.Migrations.CreatePokerCampaignsAndMatches do
  use Ecto.Migration

  def change do
    create table(:poker_campaigns) do
      add :cash, :integer, null: false, default: 1000
      add :respect, :integer, null: false, default: 0
      add :house_bracelet_earned_at, :utc_datetime_usec
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:poker_campaigns, [:user_id])

    create table(:poker_matches) do
      add :opponent_id, :string, null: false
      add :difficulty, :string, null: false, default: "standard"
      add :status, :string, null: false, default: "active"
      add :result, :string
      add :buy_in, :integer, null: false, default: 0
      add :payout, :integer, null: false, default: 0
      add :started_at, :utc_datetime_usec, null: false
      add :completed_at, :utc_datetime_usec
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:poker_matches, [:user_id, :opponent_id, :status])
    create index(:poker_matches, [:user_id, :status])
  end
end
