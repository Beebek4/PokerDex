defmodule ZoonkWeb.Live.Play do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content.PokerHealth
  alias Zoonk.Poker.Bot.Difficulty
  alias Zoonk.Poker.Bot.Policy
  alias Zoonk.Poker.Bot.ThinkingTime
  alias Zoonk.Poker.Campaigns
  alias Zoonk.Poker.Native
  alias Zoonk.Poker.Opponents

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    campaign = Campaigns.get_or_create(socket.assigns.current_user.id)
    unresumable_match = Campaigns.get_active_match(socket.assigns.current_user.id)
    preview_all_opponents = Application.get_env(:zoonk, :play_preview_all_opponents, false) and params["preview"] == "all"

    socket =
      socket
      |> assign(:page_title, "Play")
      |> assign(:play_screen, :journey)
      |> assign(:tournament_seats, [])
      |> assign(:tournament_players, [])
      |> assign(:tournament_stacks, [])
      |> assign(:tournament_dealer_idx, 0)
      |> assign(:is_tournament, false)
      |> assign(:campaign_cash, campaign.cash)
      |> assign(:respect, campaign.respect)
      |> assign(:unresumable_match, unresumable_match)
      |> assign(:preview_all_opponents, preview_all_opponents)
      |> assign(:demo_match, false)
      |> assign(:journey_locations, journey_locations(campaign.cash, campaign.respect, preview_all_opponents))
      |> assign(:opponent, Opponents.get("teddy"))
      |> assign(:difficulty, "easy")
      |> assign(:game_session, nil)
      |> assign(:game_view, nil)
      |> assign(:hand_id, 0)
      |> assign(:bot_thinking, false)
      |> assign(:bot_thinking_name, nil)
      |> assign(:hero_total_chips, PokerHealth.starting_chips())
      |> assign(:bot_total_chips, PokerHealth.starting_chips())
      |> assign(:match_start_chips, PokerHealth.starting_chips())
      |> assign(:active_match_id, nil)
      |> assign(:hero_health_chips, PokerHealth.starting_chips())
      |> assign(:bot_health_chips, PokerHealth.starting_chips())
      |> assign(:match_over, false)
      |> assign(:raise_to, "")
      |> assign(:raise_adjusted, false)
      |> assign(:game_message, nil)
      |> assign(:game_error, nil)
      |> assign(:hero_folded, false)
      |> assign(:action_history, [])
      |> assign(:history_street, "Preflop")
      |> assign(:streets, [{"Preflop", "PRE"}, {"Flop", "FLOP"}, {"Turn", "TURN"}, {"River", "RIVER"}])

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("player-action", %{"action" => action}, socket) when action in ["fold", "call", "check"] do
    if socket.assigns.game_view.human_action_enabled do
      submit_action(socket, action, 0.0)
    else
      {:noreply, assign(socket, :game_error, "Start a new hand to play.")}
    end
  end

  def handle_event("raise", %{"amount" => raw_amount}, socket) do
    view = socket.assigns.game_view

    case Integer.parse(raw_amount) do
      {amount, ""}
      when view.human_action_enabled and amount >= view.min_raise and amount <= view.max_raise ->
        submit_action(socket, "raise", amount * 1.0)

      _ ->
        {:noreply,
         socket
         |> assign(:raise_to, raw_amount)
         |> assign(:game_message, nil)
         |> assign(:game_error, "Choose a raise amount between the displayed limits.")}
    end
  end

  def handle_event("set-raise-size", %{"amount" => raw_amount}, socket) do
    case Integer.parse(raw_amount) do
      {amount, ""} ->
        view = socket.assigns.game_view

        if view.human_action_enabled and amount >= view.min_raise and amount <= view.max_raise do
          {:noreply,
           socket
           |> assign(:raise_to, Integer.to_string(amount))
           |> assign(:raise_adjusted, true)
           |> assign(:game_error, nil)}
        else
          {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("raise-ten-percent", _params, socket) do
    view = socket.assigns.game_view

    if view.human_action_enabled and view.min_raise <= view.max_raise do
      min_raise = round(view.min_raise)
      max_raise = round(view.max_raise)

      selected_amount =
        case Integer.parse(socket.assigns.raise_to) do
          {amount, ""} -> amount
          _ -> min_raise
        end

      amount =
        selected_amount
        |> max(min_raise)
        |> min(max_raise)
        |> Kernel.+(max(1, round(view.hero_stack * 0.10)))
        |> min(max_raise)

      {:noreply,
       socket
       |> assign(:raise_to, Integer.to_string(amount))
       |> assign(:raise_adjusted, true)
       |> assign(:game_error, nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("start-match", %{"opponent-id" => opponent_id}, socket) do
    opponent = Opponents.get(opponent_id)

    if opponent && opponent_open?(socket, opponent_id) do
      start_match(socket, opponent)
    else
      {:noreply, socket}
    end
  end

  def handle_event("start-match", _params, socket), do: {:noreply, socket}

  def handle_event("start-tournament", _params, socket) do
    tournament = Opponents.tournament()
    location = Enum.find(socket.assigns.journey_locations, &(&1.id == "house-tournament"))

    cond do
      socket.assigns.preview_all_opponents ->
        {:noreply, start_tournament_demo(socket, tournament)}

      location && location.status == :open ->
        start_saved_tournament(socket, tournament)

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("refund-pending-match", _params, socket) do
    {:ok, campaign} = Campaigns.abandon_active_matches(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(:unresumable_match, nil)
     |> assign(:campaign_cash, campaign.cash)
     |> assign(:respect, campaign.respect)
     |> assign(:journey_locations, journey_locations(campaign.cash, campaign.respect, socket.assigns.preview_all_opponents))}
  end

  def handle_event("back-to-journey", _params, socket) do
    socket = abandon_current_match(socket)
    {:noreply, assign(socket, :play_screen, :journey)}
  end

  def handle_event("new-hand", _params, %{assigns: %{match_over: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("new-hand", _params, %{assigns: %{is_tournament: true}} = socket) do
    dealer_idx = next_tournament_dealer(socket.assigns.game_view, socket.assigns.tournament_dealer_idx)

    {:noreply,
     socket
     |> assign(:tournament_dealer_idx, dealer_idx)
     |> deal_new_hand()}
  end

  def handle_event("new-hand", _params, socket) do
    {:noreply, deal_new_hand(socket)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_info({:bot_action, hand_id, bot_view, decision}, socket) do
    if hand_id == socket.assigns.hand_id and socket.assigns.play_screen == :table and
         (not is_nil(socket.assigns.active_match_id) or socket.assigns.demo_match) and
         socket.assigns.game_view.acting_player == bot_view.acting_player and bot_view.acting_player > 0 do
      apply_bot_action(socket, bot_view, decision)
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp opponent_open?(socket, opponent_id) do
    socket.assigns.journey_locations
    |> Enum.flat_map(&Map.get(&1, :opponents, []))
    |> Enum.any?(&(&1.id == opponent_id and &1.status == :open))
  end

  defp start_match(socket, opponent) do
    if socket.assigns.preview_all_opponents do
      start_preview_match(socket, opponent)
    else
      start_saved_match(socket, opponent)
    end
  end

  defp start_saved_match(socket, opponent) do
    case Campaigns.start_match(
           socket.assigns.current_user.id,
           opponent,
           opponent.difficulty
         ) do
      {:ok, {campaign, match}} ->
        starting_stack = starting_match_stack(opponent)

        socket =
          socket
          |> assign(:opponent, opponent)
          |> assign(:is_tournament, false)
          |> assign(:demo_match, false)
          |> assign(:difficulty, opponent.difficulty)
          |> assign(:campaign_cash, campaign.cash)
          |> assign(:respect, campaign.respect)
          |> assign(:journey_locations, Opponents.locations(campaign.cash, campaign.respect))
          |> assign(:hero_total_chips, starting_stack)
          |> assign(:bot_total_chips, starting_stack)
          |> assign(:hand_id, 0)
          |> assign(:match_start_chips, starting_stack)
          |> assign(:active_match_id, match.id)
          |> assign(:match_over, false)
          |> deal_new_hand()

        {:noreply, assign(socket, :play_screen, :table)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  defp start_preview_match(socket, opponent) do
    starting_stack = starting_match_stack(opponent)

    socket =
      socket
      |> assign(:opponent, opponent)
      |> assign(:is_tournament, false)
      |> assign(:demo_match, true)
      |> assign(:difficulty, opponent.difficulty)
      |> assign(:hero_total_chips, starting_stack)
      |> assign(:bot_total_chips, starting_stack)
      |> assign(:match_start_chips, starting_stack)
      |> assign(:active_match_id, nil)
      |> assign(:hand_id, 0)
      |> assign(:match_over, false)
      |> deal_new_hand()

    {:noreply, assign(socket, :play_screen, :table)}
  end

  defp start_saved_tournament(socket, tournament) do
    case Campaigns.start_match(socket.assigns.current_user.id, tournament, tournament.difficulty) do
      {:ok, {campaign, match}} ->
        seats = tournament_seating()
        players = Enum.map(seats, & &1.opponent)
        starting_stack = tournament.buy_in * 1.0
        stacks = List.duplicate(starting_stack, length(players) + 1)

        socket =
          socket
          |> assign(:opponent, tournament)
          |> assign(:is_tournament, true)
          |> assign(:demo_match, false)
          |> assign(:tournament_seats, seats)
          |> assign(:tournament_players, players)
          |> assign(:tournament_stacks, stacks)
          |> assign(:tournament_dealer_idx, 0)
          |> assign(:difficulty, tournament.difficulty)
          |> assign(:campaign_cash, campaign.cash)
          |> assign(:respect, campaign.respect)
          |> assign(:journey_locations, Opponents.locations(campaign.cash, campaign.respect))
          |> assign(:hero_total_chips, starting_stack)
          |> assign(:bot_total_chips, starting_stack)
          |> assign(:match_start_chips, starting_stack)
          |> assign(:active_match_id, match.id)
          |> assign(:match_over, false)
          |> assign(:hand_id, 0)
          |> deal_new_hand()

        {:noreply, assign(socket, :play_screen, :table)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  defp start_tournament_demo(socket, tournament) do
    seats = tournament_seating()
    players = Enum.map(seats, & &1.opponent)
    starting_stack = tournament.buy_in * 1.0

    socket =
      socket
      |> assign(:opponent, tournament)
      |> assign(:is_tournament, true)
      |> assign(:demo_match, true)
      |> assign(:tournament_seats, seats)
      |> assign(:tournament_players, players)
      |> assign(:tournament_stacks, List.duplicate(starting_stack, length(players) + 1))
      |> assign(:tournament_dealer_idx, 0)
      |> assign(:difficulty, tournament.difficulty)
      |> assign(:hero_total_chips, starting_stack)
      |> assign(:bot_total_chips, starting_stack)
      |> assign(:match_start_chips, starting_stack)
      |> assign(:active_match_id, nil)
      |> assign(:match_over, false)
      |> assign(:hand_id, 0)
      |> deal_new_hand()

    assign(socket, :play_screen, :table)
  end

  defp tournament_seating do
    positions = ["upper-left", "upper-right", "opposite", "lower-right", "lower-left"]
    position_order = Map.new(Enum.with_index(positions))

    Opponents.all()
    |> Enum.reject(&(&1.id == "teddy"))
    |> Enum.shuffle()
    |> Enum.zip(positions)
    |> Enum.map(fn {opponent, position} -> %{opponent: opponent, position: position} end)
    |> Enum.sort_by(&Map.fetch!(position_order, &1.position))
  end

  defp next_tournament_dealer(view, dealer_idx) do
    view.player_stacks
    |> Enum.with_index()
    |> Enum.sort_by(fn {_stack, idx} -> rem(idx - dealer_idx - 1 + length(view.player_stacks), length(view.player_stacks)) end)
    |> Enum.find_value(dealer_idx, fn {stack, idx} -> if stack > 0, do: idx end)
  end

  defp journey_locations(cash, respect, true) do
    cash
    |> Opponents.locations(respect)
    |> Enum.map(fn
      %{id: "home", opponents: opponents} = location ->
        unlocked = Enum.map(opponents, &Map.merge(&1, %{status: :open, lock_reason: nil}))
        %{location | opponents: unlocked}

      %{id: "house-tournament"} = location ->
        location
        |> Map.put(:status, :open)
        |> Map.put(:requirements_met?, true)

      location ->
        location
    end)
  end

  defp journey_locations(cash, respect, false), do: Opponents.locations(cash, respect)

  defp abandon_current_match(%{assigns: %{active_match_id: nil, demo_match: true}} = socket) do
    socket
    |> assign(:demo_match, false)
    |> assign(:bot_thinking, false)
    |> assign(:game_session, nil)
    |> update(:hand_id, &(&1 + 1))
  end

  defp abandon_current_match(%{assigns: %{active_match_id: nil}} = socket), do: socket

  defp abandon_current_match(socket) do
    Campaigns.abandon_active_matches(socket.assigns.current_user.id)
    campaign = Campaigns.get_or_create(socket.assigns.current_user.id)

    socket
    |> assign(:campaign_cash, campaign.cash)
    |> assign(:respect, campaign.respect)
    |> assign(:unresumable_match, nil)
    |> assign(:journey_locations, Opponents.locations(campaign.cash, campaign.respect))
    |> assign(:active_match_id, nil)
    |> assign(:game_session, nil)
    |> assign(:bot_thinking, false)
  end

  defp submit_action(socket, action, amount) do
    previous_view = socket.assigns.game_view
    view = Native.player_action(socket.assigns.game_session, 0, action, amount)
    action_history = append_action_history(socket.assigns.action_history, previous_view, action, amount, player_name(socket, previous_view.acting_player))

    socket =
      socket
      |> assign(:action_history, action_history)
      |> maybe_schedule_bot_action(view)

    view = hide_bot_private_cards(view)
    history_street = if view.round == "Complete", do: previous_view.round, else: view.round

    {:noreply,
     socket
     |> assign(:game_view, view)
     |> assign(:history_street, history_street)
     |> assign(:hero_folded, action == "fold")
     |> assign(:raise_to, chip_text(view.min_raise))
     |> assign(:raise_adjusted, false)
     |> assign(:game_message, if(socket.assigns.bot_thinking, do: nil, else: hand_message(view, action, socket)))
     |> assign(:game_error, nil)
     |> update_battle_totals(view)}
  rescue
    ArgumentError ->
      {:noreply,
       socket
       |> assign(:game_message, nil)
       |> assign(:game_error, "That action is not available in this spot.")}
  end

  defp maybe_schedule_bot_action(socket, %{round: round, acting_player: actor} = view) when round != "Complete" and actor > 0 do
    opponent = bot_opponent(socket, actor)

    decision =
      view
      |> Policy.from_game_view()
      |> Policy.choose(opponent, opponent.difficulty)

    mode = if socket.assigns.is_tournament, do: :tournament, else: :cash_game
    delay = ThinkingTime.delay_ms(opponent, decision, mode)
    Process.send_after(self(), {:bot_action, socket.assigns.hand_id, view, decision}, delay)

    socket
    |> assign(:bot_thinking, true)
    |> assign(:bot_thinking_name, opponent.name)
  end

  defp maybe_schedule_bot_action(socket, _view) do
    socket
    |> assign(:bot_thinking, false)
    |> assign(:bot_thinking_name, nil)
  end

  defp apply_bot_action(socket, view, decision) do
    actor = view.acting_player
    bot = bot_opponent(socket, actor)
    next_view = Native.player_action(socket.assigns.game_session, actor, decision.action, decision.amount * 1.0)

    history =
      append_action_history(
        socket.assigns.action_history,
        view,
        decision.action,
        decision.amount,
        bot.name
      )

    socket =
      socket
      |> assign(:action_history, history)
      |> maybe_schedule_bot_action(next_view)

    next_view = hide_bot_private_cards(next_view)
    history_street = if next_view.round == "Complete", do: view.round, else: next_view.round

    {:noreply,
     socket
     |> assign(:game_view, next_view)
     |> assign(:history_street, history_street)
     |> assign(:game_message, if(socket.assigns.bot_thinking, do: nil, else: hand_message(next_view, decision.action, socket)))
     |> assign(:raise_to, chip_text(next_view.min_raise))
     |> assign(:raise_adjusted, false)
     |> assign(:game_error, nil)
     |> update_battle_totals(next_view)}
  rescue
    ArgumentError ->
      {:noreply,
       socket
       |> assign(:bot_thinking, false)
       |> assign(:game_error, "The bot could not complete that action. Deal a new hand to continue.")}
  end

  defp hide_bot_private_cards(view), do: %{view | bot_private_cards: []}

  defp starting_match_stack(%{buy_in: buy_in}), do: max(buy_in, trunc(PokerHealth.starting_chips()))

  defp deal_new_hand(socket) do
    if socket.assigns.is_tournament do
      deal_tournament_hand(socket)
    else
      deal_heads_up_hand(socket)
    end
  end

  defp deal_heads_up_hand(socket) do
    dealer_idx = rem(socket.assigns.hand_id, 2)

    {session, view} =
      Native.start_play_hand_with_button(
        socket.assigns.hero_total_chips,
        socket.assigns.bot_total_chips,
        socket.assigns.opponent.small_blind * 1.0,
        socket.assigns.opponent.big_blind * 1.0,
        dealer_idx
      )

    socket
    |> assign(:game_session, session)
    |> assign(:game_view, hide_bot_private_cards(view))
    |> assign(:action_history, blind_history(socket.assigns.opponent, dealer_idx))
    |> assign(:history_street, "Preflop")
    |> assign(:hero_health_chips, view.hero_stack)
    |> assign(:bot_health_chips, view.bot_stack)
    |> update(:hand_id, &(&1 + 1))
    |> assign(:hero_folded, false)
    |> assign(:raise_to, chip_text(view.min_raise))
    |> assign(:raise_adjusted, false)
    |> assign(:game_message, nil)
    |> assign(:game_error, nil)
    |> assign(:bot_thinking, false)
    |> maybe_schedule_bot_action(view)
  end

  defp deal_tournament_hand(socket) do
    dealer_idx = socket.assigns.tournament_dealer_idx
    tournament = socket.assigns.opponent

    {session, view} =
      Native.start_tournament_hand(
        socket.assigns.tournament_stacks,
        dealer_idx,
        tournament.small_blind * 1.0,
        tournament.big_blind * 1.0
      )

    socket
    |> assign(:game_session, session)
    |> assign(:game_view, hide_bot_private_cards(view))
    |> assign(:tournament_dealer_idx, view.dealer_idx)
    |> assign(:tournament_stacks, view.player_stacks)
    |> assign(:action_history, tournament_blind_history(socket.assigns.tournament_players, view, tournament))
    |> assign(:history_street, "Preflop")
    |> assign(:hero_health_chips, view.hero_stack)
    |> assign(:bot_health_chips, view.bot_stack)
    |> update(:hand_id, &(&1 + 1))
    |> assign(:hero_folded, false)
    |> assign(:raise_to, chip_text(view.min_raise))
    |> assign(:raise_adjusted, false)
    |> assign(:game_message, nil)
    |> assign(:game_error, nil)
    |> assign(:bot_thinking, false)
    |> assign(:bot_thinking_name, nil)
    |> maybe_schedule_bot_action(view)
  end

  defp update_battle_totals(socket, view) do
    if socket.assigns.is_tournament do
      update_tournament_totals(socket, view)
    else
      update_heads_up_totals(socket, view)
    end
  end

  defp update_heads_up_totals(socket, view) do
    case PokerHealth.settle(
           view,
           socket.assigns.opponent.small_blind,
           socket.assigns.opponent.big_blind
         ) do
      {:settled, hero_chips, bot_chips, match_over} ->
        socket =
          socket
          |> assign(:hero_total_chips, hero_chips)
          |> assign(:bot_total_chips, bot_chips)
          |> assign(:hero_health_chips, hero_chips)
          |> assign(:bot_health_chips, bot_chips)
          |> assign(:match_over, match_over)

        if match_over do
          winner = if hero_chips > bot_chips, do: "You take the match", else: "#{socket.assigns.opponent.name} takes the match"
          message = [socket.assigns.game_message, winner] |> Enum.reject(&is_nil/1) |> Enum.join(" · ")

          socket
          |> assign(:game_message, message)
          |> finish_campaign_match(hero_chips > bot_chips)
        else
          socket
        end

      :in_progress ->
        socket
        |> assign(:hero_health_chips, view.hero_stack)
        |> assign(:bot_health_chips, view.bot_stack)
    end
  end

  defp update_tournament_totals(socket, view) do
    hero_chips = Enum.at(view.player_stacks, 0, 0.0)
    alive = view.player_stacks |> Enum.with_index() |> Enum.filter(fn {stack, _idx} -> stack > 0 end)

    socket =
      socket
      |> assign(:tournament_stacks, view.player_stacks)
      |> assign(:hero_total_chips, hero_chips)
      |> assign(:bot_total_chips, alive |> Enum.map(&elem(&1, 0)) |> Enum.max(fn -> 0.0 end))
      |> assign(:hero_health_chips, hero_chips)
      |> assign(:bot_health_chips, alive |> Enum.map(&elem(&1, 0)) |> Enum.max(fn -> 0.0 end))

    hero_eliminated? = hero_chips <= 0
    tournament_won? = length(alive) == 1 and elem(hd(alive), 1) == 0
    tournament_finished? = hero_eliminated? or length(alive) <= 1

    if view.round == "Complete" and tournament_finished? do
      champion = if tournament_won?, do: "You", else: alive |> Enum.map(fn {_stack, idx} -> player_name(socket, idx) end) |> List.first("The family")
      result = if tournament_won?, do: "You win the Garage Tournament", else: "#{champion} wins the Garage Tournament"

      socket
      |> assign(:match_over, true)
      |> assign(:game_message, result)
      |> finish_campaign_match(tournament_won?)
    else
      socket
    end
  end

  defp finish_campaign_match(%{assigns: %{active_match_id: nil}} = socket, _won?), do: socket

  defp finish_campaign_match(socket, won?) do
    result = if won?, do: "won", else: "lost"

    case Campaigns.finish_match(socket.assigns.current_user.id, socket.assigns.active_match_id, result) do
      {:ok, %{campaign: campaign, recovery_cash: recovery_cash}} ->
        socket
        |> assign(:campaign_cash, campaign.cash)
        |> assign(:respect, campaign.respect)
        |> assign(:journey_locations, Opponents.locations(campaign.cash, campaign.respect))
        |> assign(:active_match_id, nil)
        |> maybe_announce_recovery(recovery_cash)

      {:error, _reason} ->
        socket
    end
  end

  defp maybe_announce_recovery(socket, recovery_cash) when recovery_cash > 0 do
    message = "Teddy's warm-up gives you #{recovery_cash} recovery chips."
    current_message = socket.assigns.game_message
    assign(socket, :game_message, [current_message, message] |> Enum.reject(&is_nil/1) |> Enum.join(" · "))
  end

  defp maybe_announce_recovery(socket, _recovery_cash), do: socket

  defp hand_message(%{round: "Complete", is_tie: true, pot: pot}, _action, _socket) do
    "Split pot · #{chip_text(pot / 2)} each"
  end

  defp hand_message(%{round: "Complete", winner: winner, pot: pot} = view, action, socket) when is_integer(winner) do
    player = player_name(socket, winner)
    verb = if winner == 0, do: "win", else: "wins"
    amount = chip_text(pot)

    winner_cards = Enum.at(view.player_hole_cards, winner, [])

    if action == "fold" or winner_cards == [] do
      "#{player} #{verb} #{amount} after a fold"
    else
      hand = showdown_hand_name(view, winner_cards)
      "#{player} #{verb} #{amount} with #{hand}"
    end
  end

  defp hand_message(view, _action, _socket), do: "Your turn on #{String.downcase(view.round)}."

  defp blind_history(opponent, 0) do
    [
      %{street: "Preflop", actor: "You", text: "Puts #{opponent.small_blind} SB"},
      %{street: "Preflop", actor: opponent.name, text: "Puts #{opponent.big_blind} BB"}
    ]
  end

  defp blind_history(opponent, _dealer_idx) do
    [
      %{street: "Preflop", actor: opponent.name, text: "Puts #{opponent.small_blind} SB"},
      %{street: "Preflop", actor: "You", text: "Puts #{opponent.big_blind} BB"}
    ]
  end

  defp tournament_blind_history(players, view, tournament) do
    [
      %{street: "Preflop", actor: player_name_from_tournament(players, view.small_blind_idx), text: "Puts #{chip_text(tournament.small_blind)} SB"},
      %{street: "Preflop", actor: player_name_from_tournament(players, view.big_blind_idx), text: "Puts #{chip_text(tournament.big_blind)} BB"}
    ]
  end

  defp append_action_history(history, view, action, amount, opponent_name) do
    street = view.round
    actor = if view.acting_player == 0, do: "You", else: opponent_name

    text =
      case action do
        "raise" ->
          verb = if view.to_call > 0, do: "Raise to", else: "Bet to"
          "#{verb} #{chip_text(amount)}"

        "call" ->
          "Call #{chip_text(view.to_call)}"

        "check" ->
          "Check"

        "fold" ->
          "Fold"
      end

    history ++ [%{street: street, actor: actor, text: text}]
  end

  defp actions_for_street(history, street) do
    actions =
      history
      |> Enum.filter(&(&1.street == street))
      |> Enum.take(-3)

    actions ++ List.duplicate(nil, 3 - length(actions))
  end

  defp showdown_hand_name(view, player_cards) do
    rank = Native.rank_hand(Enum.join(player_cards) <> Enum.join(view.board))

    case rank do
      "HighCard" -> "a high card"
      "OnePair" -> "a pair"
      "TwoPair" -> "two pair"
      "ThreeOfAKind" -> "three of a kind"
      "Straight" -> "a straight"
      "Flush" -> "a flush"
      "FullHouse" -> "a full house"
      "FourOfAKind" -> "four of a kind"
      "StraightFlush" -> "a straight flush"
      other -> String.downcase(other)
    end
  end

  defp bot_opponent(socket, actor) do
    if socket.assigns.is_tournament do
      Enum.at(socket.assigns.tournament_players, actor - 1, socket.assigns.opponent)
    else
      socket.assigns.opponent
    end
  end

  defp player_name(socket, 0), do: "You"

  defp player_name(socket, actor) do
    if socket.assigns.is_tournament do
      player_name_from_tournament(socket.assigns.tournament_players, actor)
    else
      socket.assigns.opponent.name
    end
  end

  defp player_name_from_tournament(players, 0), do: "You"
  defp player_name_from_tournament(players, actor), do: Enum.at(players, actor - 1, %{name: "Opponent"}).name

  defp tournament_player_index(players, opponent_id) do
    case Enum.find_index(players, &(&1.id == opponent_id)) do
      nil -> 1
      index -> index + 1
    end
  end

  defp role_text(view, player_idx) do
    roles = []
    roles = if view.dealer_idx == player_idx, do: roles ++ ["BTN"], else: roles
    roles = if view.small_blind_idx == player_idx, do: roles ++ ["SB"], else: roles
    roles = if view.big_blind_idx == player_idx, do: roles ++ ["BB"], else: roles
    Enum.join(roles, " · ")
  end

  defp chip_text(value) when is_float(value) do
    if value == trunc(value), do: Integer.to_string(trunc(value)), else: :erlang.float_to_binary(value, decimals: 1)
  end

  defp chip_text(value) when is_integer(value), do: Integer.to_string(value)

  defp blinds_text(opponent), do: "#{chip_text(opponent.small_blind)}/#{chip_text(opponent.big_blind)}"

  defp difficulty_label(opponent), do: Difficulty.get(opponent.difficulty).label

  defp character_image_path("teddy"), do: ~p"/images/poker/characters/teddy.png"
  defp character_image_path("grandpa"), do: ~p"/images/poker/characters/grandpa.png"
  defp character_image_path("mum"), do: ~p"/images/poker/characters/mum.png"
  defp character_image_path("sister"), do: ~p"/images/poker/characters/sister.png"
  defp character_image_path("brother"), do: ~p"/images/poker/characters/brother.png"
  defp character_image_path("dad"), do: ~p"/images/poker/characters/dad.png"
  defp character_image_path(_opponent_id), do: ~p"/images/poker/characters/teddy.png"

  defp game_flipped_character?(opponent_id), do: opponent_id in []

  defp map_flipped_character?(opponent_id), do: opponent_id in ["mum", "sister"]

  defp player_character_path(%{avatar: "/images/poker/characters/girl_hero.png"}), do: ~p"/images/poker/characters/girl_hero.png"

  defp player_character_path(_user), do: ~p"/images/poker/characters/hero.png"

  defp player_character_class(%{avatar: "/images/poker/characters/girl_hero.png"}), do: "play-avatar--hero-girl"

  defp player_character_class(_user), do: nil

  defp card_rank(<<rank::binary-size(1), _suit::binary-size(1)>>), do: if(rank == "T", do: "10", else: rank)
  defp card_rank(_card), do: "?"

  defp card_label(<<rank::binary-size(1), suit::binary-size(1)>>) do
    "#{card_rank(rank <> suit)} of #{suit_name(suit)}"
  end

  defp card_label(_card), do: "Unknown card"

  defp suit_name("s"), do: "spades"
  defp suit_name("h"), do: "hearts"
  defp suit_name("d"), do: "diamonds"
  defp suit_name("c"), do: "clubs"
  defp suit_name(_suit), do: "unknown suit"

  defp suit_image_path(<<_rank::binary-size(1), "s">>), do: ~p"/images/poker/suits/spade.png"
  defp suit_image_path(<<_rank::binary-size(1), "h">>), do: ~p"/images/poker/suits/heart.png"
  defp suit_image_path(<<_rank::binary-size(1), "d">>), do: ~p"/images/poker/suits/diamond.png"
  defp suit_image_path(<<_rank::binary-size(1), "c">>), do: ~p"/images/poker/suits/club.png"

  defp suit_color(<<_rank::binary-size(1), suit::binary-size(1)>>) when suit in ["h", "d"], do: "text-red-700"
  defp suit_color(_card), do: "text-slate-950"

  attr :card, :string, required: true
  attr :id, :string, default: nil
  attr :delay, :integer, default: 0
  attr :folded, :boolean, default: false
  attr :highlight, :boolean, default: false

  defp playing_card(assigns) do
    ~H"""
    <span
      id={@id}
      style={"--deal-delay: #{@delay}ms"}
      class={[
        "poker-card-fold-transition shadow-black/20 aspect-[2/3] rounded-[6px] relative block w-full overflow-hidden border border-slate-300 bg-white font-bold shadow-md sm:rounded-lg",
        !@folded && "poker-card-deal",
        @folded && "poker-card-fold",
        @highlight && "poker-card-best",
        suit_color(@card)
      ]}
      role="img"
      aria-label={if @highlight, do: "#{card_label(@card)} · part of the winning hand", else: card_label(@card)}
    >
      <span class="left-[7%] top-[5%] text-[0.68rem] absolute leading-none sm:text-sm"><%= card_rank(@card) %></span>
      <img src={suit_image_path(@card)} alt="" aria-hidden="true" class="h-[64%] max-w-[64%] absolute top-1/2 left-1/2 w-auto -translate-x-1/2 -translate-y-1/2 object-contain" />
      <span class="bottom-[5%] right-[7%] text-[0.68rem] absolute rotate-180 leading-none sm:text-sm"><%= card_rank(@card) %></span>
    </span>
    """
  end

  attr :id, :string, required: true
  attr :amount, :string, required: true
  attr :pot, :float, required: true
  attr :initial_buy_in, :float, required: true

  defp pot_display(assigns) do
    ~H"""
    <div
      id={@id}
      class="poker-pot-display top-[70%] absolute left-1/2 z-20 flex -translate-x-1/2 -translate-y-1/2 flex-col items-center"
      role="status"
      aria-label={"Pot: #{@amount} chips"}
    >
      <img src={pot_image_path(@pot, @initial_buy_in)} alt="" aria-hidden="true" class="poker-pot-art" />
      <strong class="poker-pot-amount tabular-nums"><%= @amount %></strong>
    </div>
    """
  end

  defp pot_image_path(pot, initial_buy_in) when is_number(initial_buy_in) and initial_buy_in > 0 and pot < initial_buy_in * 0.3, do: ~p"/images/poker/pots/small_pot.png"

  defp pot_image_path(pot, initial_buy_in) when is_number(initial_buy_in) and initial_buy_in > 0 and pot < initial_buy_in * 0.8, do: ~p"/images/poker/pots/medium_pot.png"

  defp pot_image_path(_pot, _initial_buy_in), do: ~p"/images/poker/pots/large_pot.png"
end
