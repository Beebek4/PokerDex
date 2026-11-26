defmodule Zoonk.Repo.Migrations.SetPokerCampaignStartingChips do
  use Ecto.Migration

  def up do
    alter table(:poker_campaigns) do
      modify :cash, :integer, default: 100
    end
  end

  def down do
    alter table(:poker_campaigns) do
      modify :cash, :integer, default: 1000
    end
  end
end
