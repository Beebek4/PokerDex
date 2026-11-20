defmodule ZoonkWeb.PlayLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :app_setup

  test "Play starts a real poker session and sends call/check actions to the engine", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")

    assert has_element?(lv, "h1", "Heads-up table")
    assert has_element?(lv, "button", "Call 5")
    assert has_element?(lv, "button", "Fold")
    assert has_element?(lv, "input#raise-to")
    assert has_element?(lv, "span[aria-label='Dealer button · You']")
    assert has_element?(lv, "div[aria-label='Bot hole cards face down']")
    assert has_element?(lv, "div.opponent-card-back img")
    refute has_element?(lv, ".play-health-overflow")
    assert has_element?(lv, "div.play-actions")
    assert has_element?(lv, "div.play-status")
    assert has_element?(lv, "img[src='/images/poker/tables/poker_table1.png']")
    assert has_element?(lv, "img[src='/images/poker/backgrounds/livingroom_background.png']")

    lv |> element("button", "Call 5") |> render_click()

    assert has_element?(lv, "span", "Flop")
    assert has_element?(lv, "progress.play-health-track[aria-label='Your remaining chips'][aria-valuenow='90'][value='90']")
    assert has_element?(lv, "progress.play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='90'][value='90']")
    assert has_element?(lv, "button", "Check")
    assert has_element?(lv, "div[role='group'][aria-label^='Community cards:']")

    lv |> element("button", "Check") |> render_click()
    assert has_element?(lv, "span", "Turn")

    lv |> element("button", "Check") |> render_click()
    assert has_element?(lv, "span", "River")

    lv |> element("button", "Check") |> render_click()

    assert has_element?(lv, "span", "Hand complete")
    assert has_element?(lv, "button", "Deal next hand")
    assert has_element?(lv, ".play-actions .play-action-reserve")
    assert has_element?(lv, "div[aria-label='Bot hole cards revealed']")
    assert has_element?(lv, "div[aria-label='Bot hole cards revealed'].grid")
  end

  test "Play validates raise size and starts a fresh hand after a fold", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")

    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='95']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='90']")

    lv |> form("form[phx-submit='raise']", %{"amount" => "11"}) |> render_submit()
    assert has_element?(lv, "p", "Choose a raise amount between the displayed limits.")
    assert has_element?(lv, "button", "Call 5")

    lv |> element("button", "Fold") |> render_click()
    assert has_element?(lv, "p", "Bot wins 15 after a fold")
    assert has_element?(lv, "progress.play-health-track[aria-label='Your remaining chips'][aria-valuenow='95'][value='95']")
    assert has_element?(lv, "progress.play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='105'][value='100']")
    assert has_element?(lv, ".play-health-shell > progress.play-health-overflow[value='5']")
    assert has_element?(lv, ".play-player-stack", "95")
    assert has_element?(lv, ".play-player-stack", "105")
    assert has_element?(lv, "button", "Deal next hand")
    assert has_element?(lv, ".play-actions .play-action-reserve")
    refute has_element?(lv, "div[aria-label='Bot hole cards revealed']")

    lv |> element("button", "Deal next hand") |> render_click()
    assert has_element?(lv, "span", "Preflop")
    assert has_element?(lv, "button", "Call 5")
    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='90']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='95']")
    assert has_element?(lv, ".play-player-stack", "90")
    assert has_element?(lv, ".play-player-stack", "95")
    refute has_element?(lv, ".play-actions .play-action-reserve")

    lv |> element("button", "Fold") |> render_click()
    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='90']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='110']")
    assert has_element?(lv, ".play-health-overflow[value='10']")
  end

  test "Play submits a legal raise and advances to the flop", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")

    lv |> form("form[phx-submit='raise']", %{"amount" => "20"}) |> render_submit()

    assert has_element?(lv, "span", "Flop")
    assert has_element?(lv, "p", "Your turn on flop.")
    assert has_element?(lv, ".poker-pot-display[aria-label='Pot: 40 chips']")
    assert has_element?(lv, ".play-health-track[aria-label='Your remaining chips'][aria-valuenow='80']")
    assert has_element?(lv, ".play-health-track[aria-label='Opponent remaining chips'][aria-valuenow='80']")
    assert has_element?(lv, ".play-player-stack", "80")
  end

  test "raise slider updates the selected size before adding chips to the pot", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/play")
    raise_form = "form[phx-change='set-raise-size']"

    lv |> form(raise_form, %{"amount" => "30"}) |> render_change()
    assert has_element?(lv, "output", "30")

    lv |> form(raise_form, %{"amount" => "30"}) |> render_submit()

    assert has_element?(lv, "span", "Flop")
    assert has_element?(lv, ".poker-pot-display[aria-label='Pot: 60 chips']")
  end
end
