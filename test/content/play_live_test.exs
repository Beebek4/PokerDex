defmodule ZoonkWeb.PlayLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Zoonk.Poker.Campaigns
  alias Zoonk.Poker.Match
  alias Zoonk.Poker.Opponents
  alias Zoonk.Repo

  setup :app_setup

  test "a refreshed match stays reserved until the player explicitly refunds it", %{conn: conn, user: user} do
    assert {:ok, {_campaign, match}} = Campaigns.start_match(user.id, Opponents.get("teddy"), "easy")

    {:ok, lv, _html} = live(conn, ~p"/play")

    assert has_element?(lv, "h2", "Your previous match can’t be resumed")
    assert %Match{status: "active"} = Repo.get!(Match, match.id)

    lv |> element("button", "Refund entry and start fresh") |> render_click()

    refute has_element?(lv, "h2", "Your previous match can’t be resumed")
    assert %Match{status: "abandoned"} = Repo.get!(Match, match.id)
    assert has_element?(lv, ".play-route-card.is-open", "Teddy")
  end

  test "Play starts a real poker session and sends call/check actions to the engine", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")

    assert has_element?(lv, "h1", "Choose your next challenge")
    assert has_element?(lv, "h2#location-home", "Home")
    assert has_element?(lv, ".play-route-card.is-open", "Teddy")
    assert has_element?(lv, ".play-route-card.is-open .play-route-label", "LEVEL 0 · WARM-UP")
    assert has_element?(lv, "img.play-route-teddy[src='/images/poker/characters/teddy.png']")
    assert has_element?(lv, ".play-route-card.is-locked", "Grandpa")
    assert has_element?(lv, ".play-route-card.is-locked", "Mum")
    assert has_element?(lv, ".play-route-card.is-locked", "Sister")
    assert has_element?(lv, ".play-route-card.is-locked", "Brother")
    assert has_element?(lv, ".play-route-card.is-locked", "Dad")
    assert has_element?(lv, "#location-house-tournament", "Garage Tournament")
    assert has_element?(lv, ".play-tournament-stop[aria-label*='Garage Tournament']")
    assert has_element?(lv, ".play-tournament-stop", "Teddy sits it out")
    lv |> element(~s|button[phx-value-opponent-id="teddy"]|) |> render_click()

    assert has_element?(lv, "h1", "Heads-up table")
    assert has_element?(lv, "button", "Call 1")
    assert has_element?(lv, "button", "Fold")
    assert has_element?(lv, "input#raise-to")
    assert has_element?(lv, "span[aria-label='Dealer button · You']")
    assert has_element?(lv, ".play-avatar img[src='/images/poker/characters/hero.png']")
    assert has_element?(lv, "div[aria-label=\"Teddy's hole cards face down\"]")
    assert has_element?(lv, ".play-avatar img[src='/images/poker/characters/teddy.png']")
    assert has_element?(lv, "div.opponent-card-back img")
    refute has_element?(lv, ".play-health-overflow")
    assert has_element?(lv, "div.play-actions")
    assert has_element?(lv, "div.play-status")
    assert has_element?(lv, "img[src='/images/poker/tables/poker_table1.png']")
    assert has_element?(lv, "img[src='/images/poker/backgrounds/livingroom_background.png']")

    lv |> element("button", "Call 1") |> render_click()

    assert_eventually(lv, "button", "Check")
    assert has_element?(lv, "progress.play-health-track[aria-label='Your remaining chips'][aria-valuenow='98'][value='98']")
    assert has_element?(lv, "progress.play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='98'][value='98']")
    assert has_element?(lv, "button", "Check")
    assert has_element?(lv, "div[role='group'][aria-label^='Community cards:']")

    lv |> element("button", "Check") |> render_click()
    assert_eventually(lv, "button", "Check")
    assert has_element?(lv, ".play-topbar span.truncate", "Turn")

    lv |> element("button", "Check") |> render_click()
    assert_eventually(lv, "button", "Check")
    assert has_element?(lv, ".play-topbar span.truncate", "River")

    lv |> element("button", "Check") |> render_click()

    assert_eventually(lv, ".play-actions span", "Hand complete")
    assert has_element?(lv, "button", "Deal next hand")
    assert has_element?(lv, ".play-actions .play-action-reserve")
    assert has_element?(lv, "div[aria-label=\"Teddy's hole cards revealed\"]")
    assert has_element?(lv, "div[aria-label=\"Teddy's hole cards revealed\"].grid")
  end

  test "a bot profile can be opened during a heads-up match", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")
    lv |> element(~s|button[phx-value-opponent-id="teddy"]|) |> render_click()

    lv
    |> element("button[aria-label=\"View Teddy's playstyle\"]")
    |> render_click()

    assert has_element?(lv, "[role='dialog'] h2", "Teddy")
    assert has_element?(lv, "[role='dialog']", "Playstyle")
    assert has_element?(lv, "[role='dialog']", "Pre-flop")
    assert has_element?(lv, "[role='dialog']", "Post-flop")
  end

  test "Play validates raise size and starts a fresh hand after a fold", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")
    lv |> element(~s|button[phx-value-opponent-id="teddy"]|) |> render_click()

    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='99']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='98']")

    lv |> form("form[phx-submit='raise']", %{"amount" => "2"}) |> render_submit()
    assert has_element?(lv, "p", "Choose a raise amount between the displayed limits.")
    assert has_element?(lv, "button", "Call 1")

    lv |> element("button", "Fold") |> render_click()
    assert has_element?(lv, "p", "Teddy wins 3 after a fold")
    assert has_element?(lv, "progress.play-health-track[aria-label='Your remaining chips'][aria-valuenow='99'][value='99']")
    assert has_element?(lv, "progress.play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='100'][value='100']")
    assert has_element?(lv, ".play-health-shell > progress.play-health-overflow[value='1']")
    assert has_element?(lv, ".play-player-stack", "99")
    assert has_element?(lv, ".play-player-stack", "101")
    assert has_element?(lv, "button", "Deal next hand")
    assert has_element?(lv, ".play-actions .play-action-reserve")
    refute has_element?(lv, "div[aria-label=\"Teddy's hole cards revealed\"]")

    lv |> element("button", "Deal next hand") |> render_click()
    assert has_element?(lv, "span", "Preflop")
    assert_element_eventually(lv, "#primary-player-action")
    assert has_element?(lv, "#primary-player-action")
    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='97']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='99']")
    assert has_element?(lv, ".play-player-stack", "97")
    assert has_element?(lv, ".play-player-stack", "99")
    refute has_element?(lv, ".play-actions .play-action-reserve")

    lv |> element("button", "Fold") |> render_click()
    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='97']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='100']")
    assert has_element?(lv, ".play-health-overflow[value='3']")
  end

  test "Play submits a legal raise and advances to the flop", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")
    lv |> element(~s|button[phx-value-opponent-id="teddy"]|) |> render_click()

    lv |> form("form[phx-submit='raise']", %{"amount" => "20"}) |> render_submit()

    assert_eventually(lv, ".play-status p", "Your turn on flop.")
    assert has_element?(lv, ".poker-pot-display[aria-label='Pot: 40 chips']")
    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='80']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='80']")
    assert has_element?(lv, ".play-player-stack", "80")
  end

  test "raise slider updates the selected size before adding chips to the pot", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")
    lv |> element(~s|button[phx-value-opponent-id="teddy"]|) |> render_click()
    raise_form = "form[phx-change='set-raise-size']"

    lv |> form(raise_form, %{"amount" => "30"}) |> render_change()
    assert has_element?(lv, "input#raise-to[value='30']")

    lv |> form(raise_form, %{"amount" => "30"}) |> render_submit()

    assert_eventually(lv, ".play-topbar span.truncate", "Flop")
    assert has_element?(lv, ".poker-pot-display[aria-label='Pot: 60 chips']")
  end

  defp assert_eventually(lv, selector, text, attempts \\ 60)
  defp assert_eventually(_lv, _selector, _text, 0), do: flunk("Timed out waiting for the Play view to update")

  defp assert_eventually(lv, selector, text, attempts) do
    if has_element?(lv, selector, text) do
      :ok
    else
      Process.sleep(50)
      assert_eventually(lv, selector, text, attempts - 1)
    end
  end

  defp assert_element_eventually(lv, selector, attempts \\ 60)
  defp assert_element_eventually(_lv, _selector, 0), do: flunk("Timed out waiting for the Play view to become actionable")

  defp assert_element_eventually(lv, selector, attempts) do
    if has_element?(lv, selector) do
      :ok
    else
      Process.sleep(50)
      assert_element_eventually(lv, selector, attempts - 1)
    end
  end
end
