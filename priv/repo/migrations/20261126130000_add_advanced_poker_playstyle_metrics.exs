defmodule Zoonk.Repo.Migrations.AddAdvancedPokerPlaystyleMetrics do
  use Ecto.Migration

  def up do
    for table <- [:poker_player_stats, :poker_opponent_stats] do
      alter table(table) do
        add :three_bet_opportunities, :integer, null: false, default: 0
        add :three_bets, :integer, null: false, default: 0
        add :cbet_opportunities, :integer, null: false, default: 0
        add :cbets, :integer, null: false, default: 0
        add :postflop_calls, :integer, null: false, default: 0
        add :saw_flop_hands, :integer, null: false, default: 0
        add :wtsd_showdowns, :integer, null: false, default: 0
      end

      execute("UPDATE #{table} SET postflop_calls = calls_when_facing_bet")
    end
  end

  def down do
    for table <- [:poker_player_stats, :poker_opponent_stats] do
      alter table(table) do
        remove :three_bet_opportunities
        remove :three_bets
        remove :cbet_opportunities
        remove :cbets
        remove :postflop_calls
        remove :saw_flop_hands
        remove :wtsd_showdowns
      end
    end
  end
end
