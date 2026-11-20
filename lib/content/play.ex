defmodule ZoonkWeb.Live.Play do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content.PokerHealth
  alias Zoonk.Poker.Native

  @journey_locations [
    %{
      id: "home",
      name: "Home",
      eyebrow: "STARTING LOCATION",
      detail: "Meet the family, one table at a time.",
      opponents: [
        %{
          id: "teddy",
          level: "LEVEL 0 · WARM-UP",
          name: "Teddy",
          personality: "Gentle",
          style: "Check/call",
          preview: "Not in the tournament.",
          buy_in: 0,
          respect_required: 0,
          respect_reward: 1,
          status: :open,
          side: :right
        },
        %{
          id: "grandpa",
          level: "LEVEL 1",
          name: "Grandpa",
          personality: "Patient",
          style: "Tight-passive",
          preview: "Few hands, few bluffs; big bets tend strong.",
          buy_in: 100,
          blinds: "1/2",
          respect_required: 1,
          status: :locked,
          side: :left
        },
        %{
          id: "mum",
          level: "LEVEL 2",
          name: "Mum",
          personality: "Social",
          style: "Loose-passive",
          preview: "Calls too often; value bet, bluff less.",
          buy_in: 200,
          blinds: "2/4",
          respect_required: 2,
          status: :locked,
          side: :right
        },
        %{
          id: "sister",
          level: "LEVEL 3",
          name: "Sister",
          personality: "Focused",
          style: "Tight-aggressive",
          preview: "Selective hands, then applies pressure.",
          buy_in: 300,
          blinds: "3/6",
          respect_required: 3,
          status: :locked,
          side: :left
        },
        %{
          id: "brother",
          level: "LEVEL 4",
          name: "Brother",
          personality: "Impulsive and unpredictable",
          style: "Loose-aggressive",
          preview: "Wide range; frequent bets and bluffs.",
          buy_in: 400,
          blinds: "4/8",
          respect_required: 4,
          status: :locked,
          side: :right
        },
        %{
          id: "dad",
          level: "LEVEL 5 · FINAL HOME MATCH",
          name: "Dad",
          personality: "Steady and readable",
          style: "Straightforward, value-heavy",
          preview: "Large bets tend strong; practise disciplined folds.",
          buy_in: 500,
          blinds: "5/10",
          respect_required: 5,
          status: :locked,
          side: :left
        }
      ]
    },
    %{
      id: "house-tournament",
      name: "House Tournament",
      eyebrow: "FINAL EVENT",
      detail: "The last stop after the family matches.",
      status: :locked,
      personality: "The family field",
      style: "Multiway tournament",
      preview: "A multiway final event for the Home opponents; Teddy sits it out.",
      buy_in: 2500,
      respect_required: 6
    }
  ]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Play")
      |> assign(:play_screen, :journey)
      |> assign(:journey_locations, @journey_locations)
      |> assign(:game_session, nil)
      |> assign(:game_view, nil)
      |> assign(:hand_id, 0)
      |> assign(:hero_total_chips, PokerHealth.starting_chips())
      |> assign(:bot_total_chips, PokerHealth.starting_chips())
      |> assign(:campaign_cash, 1000)
      |> assign(:respect, 0)
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

  def handle_event("start-match", _params, socket) do
    socket =
      cond do
        socket.assigns.match_over ->
          socket
          |> assign(:hero_total_chips, PokerHealth.starting_chips())
          |> assign(:bot_total_chips, PokerHealth.starting_chips())
          |> assign(:match_over, false)
          |> deal_new_hand()

        is_nil(socket.assigns.game_session) ->
          deal_new_hand(socket)

        true ->
          socket
      end

    {:noreply, assign(socket, :play_screen, :table)}
  end

  def handle_event("back-to-journey", _params, socket) do
    {:noreply, assign(socket, :play_screen, :journey)}
  end

  def handle_event("new-hand", _params, %{assigns: %{match_over: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("new-hand", _params, socket) do
    {:noreply, deal_new_hand(socket)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp submit_action(socket, action, amount) do
    previous_view = socket.assigns.game_view
    view = Native.human_action(socket.assigns.game_session, action, amount)
    action_history = append_action_history(socket.assigns.action_history, previous_view, action, amount)
    history_street = if view.round == "Complete", do: previous_view.round, else: view.round

    {:noreply,
     socket
     |> assign(:game_view, view)
     |> assign(:action_history, action_history)
     |> assign(:history_street, history_street)
     |> assign(:hero_folded, action == "fold")
     |> assign(:raise_to, chip_text(view.min_raise))
     |> assign(:raise_adjusted, false)
     |> assign(:game_message, hand_message(view, action))
     |> assign(:game_error, nil)
     |> update_battle_totals(view)}
  rescue
    ArgumentError ->
      {:noreply,
       socket
       |> assign(:game_message, nil)
       |> assign(:game_error, "That action is not available in this spot.")}
  end

  defp deal_new_hand(socket) do
    {session, view} =
      Native.start_human_hand(
        socket.assigns.hero_total_chips,
        socket.assigns.bot_total_chips
      )

    socket
    |> assign(:game_session, session)
    |> assign(:game_view, view)
    |> assign(:action_history, blind_history())
    |> assign(:history_street, "Preflop")
    |> assign(:hero_health_chips, view.hero_stack)
    |> assign(:bot_health_chips, view.bot_stack)
    |> update(:hand_id, &(&1 + 1))
    |> assign(:hero_folded, false)
    |> assign(:raise_to, chip_text(view.min_raise))
    |> assign(:raise_adjusted, false)
    |> assign(:game_message, nil)
    |> assign(:game_error, nil)
  end

  defp update_battle_totals(socket, view) do
    case PokerHealth.settle(view) do
      {:settled, hero_chips, bot_chips, match_over} ->
        socket =
          socket
          |> assign(:hero_total_chips, hero_chips)
          |> assign(:bot_total_chips, bot_chips)
          |> assign(:hero_health_chips, hero_chips)
          |> assign(:bot_health_chips, bot_chips)
          |> assign(:match_over, match_over)

        if match_over do
          winner = if hero_chips > bot_chips, do: "You take the match", else: "Teddy takes the match"
          message = [socket.assigns.game_message, winner] |> Enum.reject(&is_nil/1) |> Enum.join(" · ")
          assign(socket, :game_message, message)
        else
          socket
        end

      :in_progress ->
        socket
        |> assign(:hero_health_chips, view.hero_stack)
        |> assign(:bot_health_chips, view.bot_stack)
    end
  end

  defp hand_message(%{round: "Complete", is_tie: true, pot: pot}, _action) do
    "Split pot · #{chip_text(pot / 2)} each"
  end

  defp hand_message(%{round: "Complete", winner: winner, pot: pot} = view, action) when winner in [0, 1] do
    {player, verb} = if winner == 0, do: {"You", "win"}, else: {"Teddy", "wins"}
    amount = chip_text(pot)

    if action == "fold" or view.bot_cards == [] do
      "#{player} #{verb} #{amount} after a fold"
    else
      hand = showdown_hand_name(view, winner)
      "#{player} #{verb} #{amount} with #{hand}"
    end
  end

  defp hand_message(view, _action), do: "Your turn on #{String.downcase(view.round)}."

  defp blind_history do
    [
      %{street: "Preflop", actor: "You", text: "Posts 5 SB"},
      %{street: "Preflop", actor: "Teddy", text: "Posts 10 BB"}
    ]
  end

  defp append_action_history(history, view, action, amount) do
    street = view.round

    entries =
      case action do
        "raise" ->
          [
            %{street: street, actor: "You", text: "Raise to #{chip_text(amount)}"},
            %{street: street, actor: "Teddy", text: "Call"}
          ]

        "call" ->
          [%{street: street, actor: "You", text: "Call #{chip_text(view.to_call)}"}]

        "check" ->
          [
            %{street: street, actor: "You", text: "Check"},
            %{street: street, actor: "Teddy", text: "Check"}
          ]

        "fold" ->
          [%{street: street, actor: "You", text: "Fold"}]
      end

    history ++ entries
  end

  defp actions_for_street(history, street) do
    actions =
      history
      |> Enum.filter(&(&1.street == street))
      |> Enum.take(-3)

    actions ++ List.duplicate(nil, 3 - length(actions))
  end

  defp showdown_hand_name(view, winner) do
    player_cards = if winner == 0, do: view.hero_cards, else: view.bot_cards
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

  defp chip_text(value) when is_float(value) do
    if value == trunc(value), do: Integer.to_string(trunc(value)), else: :erlang.float_to_binary(value, decimals: 1)
  end

  defp chip_text(value) when is_integer(value), do: Integer.to_string(value)

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
        "poker-card-deal shadow-black/20 aspect-[2/3] rounded-[6px] relative block w-full overflow-hidden border border-slate-300 bg-white font-bold shadow-md sm:rounded-lg",
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

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp table_stat(assigns) do
    ~H"""
    <div class="min-w-0 text-center">
      <p class="text-[#A7ADC6] text-[9px] font-semibold uppercase tracking-wide sm:text-xs"><%= @label %></p>
      <p class="mt-0.5 text-sm font-extrabold tabular-nums text-white sm:text-lg"><%= @value %></p>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :amount, :string, required: true
  attr :pot, :float, required: true

  defp pot_display(assigns) do
    ~H"""
    <div
      id={@id}
      class="poker-pot-display top-[70%] absolute left-1/2 z-20 flex -translate-x-1/2 -translate-y-1/2 flex-col items-center"
      role="status"
      aria-label={"Pot: #{@amount} chips"}
    >
      <img src={pot_image_path(@pot)} alt="" aria-hidden="true" class="poker-pot-art" />
      <strong class="poker-pot-amount tabular-nums"><%= @amount %></strong>
    </div>
    """
  end

  defp pot_image_path(pot) when pot < 30, do: ~p"/images/poker/pots/small_pot.png"
  defp pot_image_path(pot) when pot < 80, do: ~p"/images/poker/pots/medium_pot.png"
  defp pot_image_path(_pot), do: ~p"/images/poker/pots/large_pot.png"
end
