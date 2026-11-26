defmodule Zoonk.Poker.Bot.Difficulty do
  @moduledoc "Shared skill tiers applied independently from an opponent's playstyle."

  @tiers %{
    "easy" => %{label: "Easy", call_adjustment: -0.12, raise_adjustment: 0.12, aggression_adjustment: -0.12, mistake_rate: 0.24},
    "standard" => %{label: "Standard", call_adjustment: 0.0, raise_adjustment: 0.0, aggression_adjustment: 0.0, mistake_rate: 0.10},
    "hard" => %{label: "Hard", call_adjustment: 0.0, raise_adjustment: -0.08, aggression_adjustment: 0.10, mistake_rate: 0.03}
  }
  @order ~w(easy standard hard)

  def all, do: Enum.map(@order, fn id -> Map.put(@tiers[id], :id, id) end)
  def get(id) when is_binary(id), do: Map.get(@tiers, id, @tiers["standard"])
  def get(_id), do: @tiers["standard"]
end
