defmodule Zoonk.Repo.Migrations.AddDailyRewardsToPokerCampaigns do
  use Ecto.Migration

  def change do
    alter table(:poker_campaigns) do
      add :day_streak, :integer, null: false, default: 0
      add :last_daily_reward_on, :date
    end
  end
end
