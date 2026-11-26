defmodule Zoonk.Poker.Bot.PlaystyleSimulationTest do
  use ExUnit.Case, async: false

  alias Zoonk.Poker.Bot.PlaystyleSimulation
  alias Zoonk.Poker.Opponents

  test "measures a bot by playing full randomized engine hands" do
    profile = PlaystyleSimulation.simulate(Opponents.get("grandpa"), 20)

    assert profile["simulation_version"] == PlaystyleSimulation.version()
    assert profile["hands_simulated"] == 20
    assert profile["hands_seen"] == 20
    assert profile["training_opponent"] == "five tight-aggressive opponents at a six-player table"
    assert profile["style_title"] in ["Tight-Aggressive", "Loose-Aggressive", "Tight-Passive", "Loose-Passive"]

    for key <- ~w(vpip_percentage pfr_percentage aggression_percentage call_percentage fold_to_bet_percentage showdown_percentage) do
      assert profile[key] in 0..100
    end
  end

  test "keeps the target policy attached to its rotating seat" do
    profile = PlaystyleSimulation.simulate(Opponents.get("teddy"), 40)

    assert profile["pfr_percentage"] == 0
    assert profile["aggression_percentage"] == 0
  end
end
