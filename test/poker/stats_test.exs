defmodule Zoonk.Poker.StatsTest do
  use Zoonk.DataCase, async: true

  import Ecto.Query
  import Zoonk.Fixtures.Accounts

  alias Zoonk.Poker.Campaigns
  alias Zoonk.Poker.MatchStats
  alias Zoonk.Poker.Opponents
  alias Zoonk.Poker.OpponentStats
  alias Zoonk.Poker.PlayerStats
  alias Zoonk.Poker.Stats
  alias Zoonk.Repo

  test "a new player is unrated and starts at the chart center" do
    user = user_fixture()

    assert %{title: "Unrated", hands_seen: 0, chart_position: %{x: 120, y: 100}} =
             Stats.get_player_profile(user.id)
  end

  test "action totals are accumulated in memory and written as one match summary" do
    user = user_fixture()
    {:ok, {_campaign, match}} = Campaigns.start_match(user.id, Opponents.get("teddy"), "easy")

    actions = [
      %{actor_index: 0, street: "Preflop", action: "call", facing_bet?: true},
      %{actor_index: 1, street: "Preflop", action: "raise", facing_bet?: true},
      %{actor_index: 0, street: "Flop", action: "call", facing_bet?: true},
      %{actor_index: 1, street: "Turn", action: "raise", facing_bet?: false}
    ]

    summary =
      :heads_up
      |> Stats.new_match()
      |> Stats.record_hand(actions, [%{index: 0, id: "hero"}, %{index: 1, id: "teddy"}], ["As", "Kd", "2c", "7h", "9s"], [false, false])

    assert summary.hands_played == 1
    assert {:ok, _result} = Campaigns.finish_match(user.id, match.id, "won", summary)
    assert {:error, :already_finished} = Campaigns.finish_match(user.id, match.id, "won", summary)
    assert Repo.aggregate(from(s in MatchStats, where: s.match_id == ^match.id), :count) == 1

    player = Repo.one!(from s in PlayerStats, where: s.user_id == ^user.id and s.mode == "heads_up")
    opponent = Repo.one!(from s in OpponentStats, where: s.user_id == ^user.id and s.opponent_id == "teddy")

    assert {player.hands_seen, player.vpip_hands, player.pfr_hands, player.calls_when_facing_bet, player.showdowns} ==
             {1, 1, 0, 1, 1}

    assert {opponent.hands_seen, opponent.vpip_hands, opponent.pfr_hands, opponent.aggressive_actions, opponent.showdowns} ==
             {1, 1, 1, 1, 1}

    assert Stats.get_opponent_profile(user.id, "teddy").hands_seen == 1

    assert %{title: "Loose-Balanced", looseness_percentage: 100, aggression_percentage: 50} =
             Stats.get_player_profile(user.id)
  end
end
