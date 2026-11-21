defmodule Zoonk.Poker.CampaignsTest do
  use Zoonk.DataCase, async: true

  import Zoonk.Fixtures.Accounts

  alias Zoonk.Poker.Campaign
  alias Zoonk.Poker.Campaigns
  alias Zoonk.Poker.Match
  alias Zoonk.Poker.Opponents
  alias Zoonk.Repo

  test "campaign progress persists across a completed match and duplicate completion is rejected" do
    user = user_fixture()

    assert {:ok, %{cash: 1_000, respect: 0}} = Campaigns.get_or_create(user.id)

    assert {:ok, {%Campaign{cash: 1_000, respect: 0}, %Match{opponent_id: "teddy", status: "active"} = warmup}} =
             Campaigns.start_match(user.id, Opponents.get("teddy"), "easy")

    assert {:ok, %{campaign: %Campaign{cash: 1_000, respect: 1}, recovery_cash: 0}} =
             Campaigns.finish_match(user.id, warmup.id, "won")

    assert {:ok, {%Campaign{cash: 900, respect: 1}, %Match{opponent_id: "grandpa"} = match}} =
             Campaigns.start_match(user.id, Opponents.get("grandpa"), "easy")

    assert {:ok, %{campaign: %Campaign{cash: 1_100, respect: 2}, recovery_cash: 0}} =
             Campaigns.finish_match(user.id, match.id, "won")

    assert {:error, :already_finished} = Campaigns.finish_match(user.id, match.id, "won")

    assert %Campaign{cash: 1_100, respect: 2} = Repo.get_by!(Campaign, user_id: user.id)
    assert %{total: %{games_played: 2, win_percentage: 100}} = Campaigns.get_progress(user.id)
  end

  test "active matches block a second start and abandonment refunds the entry exactly once" do
    user = user_fixture()
    Campaigns.get_or_create(user.id)
    opponent = Opponents.get("teddy")

    assert {:ok, {_campaign, %Match{} = match}} = Campaigns.start_match(user.id, opponent, "easy")
    assert {:error, :match_already_active} = Campaigns.start_match(user.id, opponent, "easy")

    assert {:ok, %Campaign{cash: 1_000}} = Campaigns.abandon_active_matches(user.id)
    assert {:ok, %Campaign{cash: 1_000}} = Campaigns.abandon_active_matches(user.id)
    assert %Match{status: "abandoned", payout: 0} = Repo.get!(Match, match.id)
  end

  test "campaign entry checks enforce respect and chip balance" do
    user = user_fixture()
    campaign = Campaigns.get_or_create(user.id)

    assert {:error, :respect_locked} =
             Campaigns.start_match(user.id, Opponents.get("grandpa"), "easy")

    assert {:error, :respect_locked} =
             Campaigns.start_match(user.id, Opponents.get("house-tournament"), "hard")

    campaign
    |> Campaign.changeset(%{respect: 6, cash: 2_499})
    |> Repo.update!()

    assert {:error, :insufficient_cash} =
             Campaigns.start_match(user.id, Opponents.get("house-tournament"), "hard")
  end
end
