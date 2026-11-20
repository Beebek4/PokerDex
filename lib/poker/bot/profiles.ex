defmodule Zoonk.Poker.Bot.Profiles do
  @moduledoc "Tunable tendencies shared by every bot using the rule-based policy."

  @profiles %{
    calling: %{continue: 0.0, value_bet: 1.1, aggression: 0.0, bluff: 0.0, size: 0.25},
    tight_passive: %{continue: 0.49, value_bet: 0.68, aggression: 0.08, bluff: 0.01, size: 0.35},
    loose_passive: %{continue: 0.27, value_bet: 0.50, aggression: 0.12, bluff: 0.03, size: 0.35},
    tight_aggressive: %{continue: 0.46, value_bet: 0.55, aggression: 0.58, bluff: 0.08, size: 0.55},
    loose_aggressive: %{continue: 0.29, value_bet: 0.52, aggression: 0.68, bluff: 0.18, size: 0.65},
    value_heavy: %{continue: 0.48, value_bet: 0.55, aggression: 0.34, bluff: 0.015, size: 0.55}
  }

  def get(id), do: Map.get(@profiles, id, @profiles[:calling])
end
