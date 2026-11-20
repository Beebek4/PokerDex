defmodule Zoonk.Content.PokerRulesTest do
  use ExUnit.Case, async: true

  alias Zoonk.Content.PokerRules

  test "parses rank and suit IDs and normalizes ten" do
    assert {:ok, %{rank: 10, suit: "h", code: "Th"}} = PokerRules.parse_card("10H")
  end

  test "rejects invalid and duplicate physical cards" do
    assert {:error, _reason} = PokerRules.parse_card("1x")
    assert {:error, "duplicate card in deal"} = PokerRules.validate_cards(["As", "AS"])
  end

  test "evaluates straight flushes and ace-low straights correctly" do
    assert {:ok, %{category: :straight_flush, tiebreaker: [14]}} =
             PokerRules.evaluate_hand(["As", "Ks", "Qs", "Js", "Ts"])

    assert {:ok, %{category: :straight, tiebreaker: [5]}} =
             PokerRules.evaluate_hand(["As", "2d", "3h", "4c", "5s"])
  end

  test "orders all standard five-card hand categories" do
    hands = [
      {:high_card, ["As", "Kd", "Qh", "9c", "3s"]},
      {:one_pair, ["As", "Ah", "Kd", "Qc", "2s"]},
      {:two_pair, ["As", "Ah", "Kd", "Kc", "2s"]},
      {:three_of_a_kind, ["As", "Ah", "Ad", "Kc", "2s"]},
      {:straight, ["9s", "8h", "7d", "6c", "5s"]},
      {:flush, ["As", "Js", "8s", "5s", "2s"]},
      {:full_house, ["As", "Ah", "Ad", "Kc", "Kh"]},
      {:four_of_a_kind, ["As", "Ah", "Ad", "Ac", "Kh"]},
      {:straight_flush, ["9s", "8s", "7s", "6s", "5s"]}
    ]

    assert Enum.map(hands, fn {category, cards} ->
             assert {:ok, %{category: ^category}} = PokerRules.evaluate_hand(cards)
             category
           end) == [
             :high_card,
             :one_pair,
             :two_pair,
             :three_of_a_kind,
             :straight,
             :flush,
             :full_house,
             :four_of_a_kind,
             :straight_flush
           ]
  end

  test "compares category and kicker ranks" do
    assert {:ok, :first} =
             PokerRules.compare_hands(["As", "Ah", "Kd", "Qc", "2s"], ["Ks", "Kh", "Ad", "Qc", "2s"])

    assert {:ok, :second} =
             PokerRules.compare_hands(["9s", "9h", "9d", "9c", "As"], ["Ts", "Th", "Td", "Tc", "2s"])
  end

  test "recognizes tied hands and returns every tied winner" do
    assert {:ok, :tie} =
             PokerRules.compare_hands(["As", "Ks", "Qs", "Js", "Ts"], ["Ah", "Kh", "Qh", "Jh", "Th"])

    players = [
      %{"id" => "hero", "hole_cards" => ["2d", "3c"]},
      %{"id" => "villain", "hole_cards" => ["4d", "5c"]}
    ]

    assert {:ok, %{winners: ["hero", "villain"]}} = PokerRules.rank_players(players, ["As", "Ks", "Qs", "Js", "Ts"])
  end

  test "splits a tied pot evenly and rejects duplicate winners" do
    assert {:ok, %{"hero" => 3.5, "villain" => 3.5}} = PokerRules.split_pot(7, ["hero", "villain"])
    assert {:error, _reason} = PokerRules.split_pot(7, ["hero", "hero"])
  end

  test "ranks players with the same board and distinct hole cards" do
    players = [
      %{"id" => "hero", "hole_cards" => ["As", "Kd"]},
      %{"id" => "villain", "hole_cards" => ["6d", "Qd"]}
    ]

    assert {:ok, %{winners: ["villain"]}} = PokerRules.rank_players(players, ["2c", "3d", "4h", "5s", "9c"])
  end

  test "derives the action names that are legal from amount to call and remaining stack" do
    assert {:ok, ["check", "bet"]} = PokerRules.legal_actions(0, 20)
    assert {:ok, ["fold", "call"]} = PokerRules.legal_actions(1, 1)
    assert {:ok, ["fold", "call", "raise"]} = PokerRules.legal_actions(1, 20)
    assert {:ok, []} = PokerRules.legal_actions(0, 0)
    assert {:error, _reason} = PokerRules.legal_actions(-1, 10)
  end

  test "rejects a scenario whose listed action set disagrees with its state" do
    scenario = %{
      "table" => %{"seat_count" => 6},
      "hero" => %{"seat" => 2, "hole_cards" => ["As", "Kd"], "starting_stack_bb" => 100, "remaining_stack_bb" => 100},
      "effective_stack_bb" => 100,
      "board" => [],
      "question" => %{"type" => "choose_action"},
      "pot" => 1.5,
      "action_state" => %{
        "amount_to_call_bb" => 0,
        "street_bet_bb" => 0,
        "hero_street_contribution_bb" => 0,
        "contributions_by_seat_bb" => [0.5, 0, 0, 0, 1, 0]
      },
      "legal_actions" => ["fold", "call"]
    }

    assert "legal_actions do not match the amount to call and remaining stack" in PokerRules.validate_scenario(scenario)
  end

  test "rejects a pot that does not match the committed chips" do
    scenario = %{
      "table" => %{"seat_count" => 6},
      "hero" => %{"seat" => 2, "hole_cards" => ["As", "Kd"], "starting_stack_bb" => 100, "remaining_stack_bb" => 100},
      "effective_stack_bb" => 100,
      "board" => [],
      "question" => %{"type" => "choose_action"},
      "pot" => 2,
      "action_state" => %{
        "amount_to_call_bb" => 1,
        "street_bet_bb" => 1,
        "hero_street_contribution_bb" => 0,
        "contributions_by_seat_bb" => [0.5, 0, 0, 0, 1, 0]
      },
      "legal_actions" => ["fold", "call", "raise"]
    }

    assert "pot does not equal the sum of contributions_by_seat_bb" in PokerRules.validate_scenario(scenario)
  end
end
