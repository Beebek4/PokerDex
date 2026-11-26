defmodule Zoonk.Repo.Migrations.CreatePokerPlaystyleAndRetentionStats do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :retention_study_opt_in, :boolean, null: false, default: false
    end

    create table(:poker_match_stats) do
      add :match_id, references(:poker_matches, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :mode, :string, null: false
      add :hands_played, :integer, null: false, default: 0
      add :metrics, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:poker_match_stats, [:match_id])
    create index(:poker_match_stats, [:user_id, :mode, :inserted_at])

    create table(:poker_player_stats) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :mode, :string, null: false
      add :hands_seen, :integer, null: false, default: 0
      add :vpip_hands, :integer, null: false, default: 0
      add :pfr_hands, :integer, null: false, default: 0
      add :postflop_actions, :integer, null: false, default: 0
      add :aggressive_actions, :integer, null: false, default: 0
      add :facing_bet_decisions, :integer, null: false, default: 0
      add :calls_when_facing_bet, :integer, null: false, default: 0
      add :folds_when_facing_bet, :integer, null: false, default: 0
      add :showdowns, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:poker_player_stats, [:user_id, :mode])

    create table(:poker_opponent_stats) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :opponent_id, :string, null: false
      add :mode, :string, null: false
      add :hands_seen, :integer, null: false, default: 0
      add :vpip_hands, :integer, null: false, default: 0
      add :pfr_hands, :integer, null: false, default: 0
      add :postflop_actions, :integer, null: false, default: 0
      add :aggressive_actions, :integer, null: false, default: 0
      add :facing_bet_decisions, :integer, null: false, default: 0
      add :calls_when_facing_bet, :integer, null: false, default: 0
      add :folds_when_facing_bet, :integer, null: false, default: 0
      add :showdowns, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:poker_opponent_stats, [:user_id, :opponent_id, :mode])
    create index(:poker_opponent_stats, [:user_id, :opponent_id])

    create table(:retention_outbox_events) do
      add :event_id, :binary_id, null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      add :event_name, :string, null: false
      add :schema_version, :integer, null: false, default: 1
      add :payload, :map, null: false, default: %{}
      add :occurred_at, :utc_datetime_usec, null: false
      add :published_at, :utc_datetime_usec
      add :locked_at, :utc_datetime_usec
      add :attempts, :integer, null: false, default: 0

      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create unique_index(:retention_outbox_events, [:event_id])
    create index(:retention_outbox_events, [:inserted_at], where: "published_at IS NULL")
    create index(:retention_outbox_events, [:user_id, :event_name])
  end
end
