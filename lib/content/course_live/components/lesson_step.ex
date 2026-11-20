# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Content.LessonStep do
  @moduledoc false
  use ZoonkWeb, :html

  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Shared.YouTube
  alias Zoonk.Storage

  attr :step, LessonStep, required: true
  attr :selected, StepOption, default: nil

  def lesson_step(assigns) do
    ~H"""
    <div class="flex w-full flex-col items-center justify-center gap-4">
      <img :if={@step.image} src={Storage.get_url(@step.image)} class="w-full" />

      <blockquote :if={is_nil(@step.poker_scenario)} class="w-fit rounded-2xl bg-gray-50 p-4 text-sm leading-6 text-gray-900 sm:text-lg">
        <p><%= YouTube.remove_from_string(@step.content) %></p>
      </blockquote>

      <.youtube :if={is_nil(@step.poker_scenario)} content={@step.content} />

      <section
        :if={@step.poker_scenario}
        class="border-white/15 bg-[#351B2B] shadow-black/25 w-full overflow-hidden rounded-3xl border text-white shadow-xl"
        aria-label="Poker scenario"
      >
        <% scenario = @step.poker_scenario %>
        <% hero = scenario["hero"] || %{} %>
        <% table = scenario["table"] || %{} %>
        <% opponents = opponent_seats(hero["seat"], table["seat_count"]) %>
        <% dealer = dealer_seat(hero["seat"], table["button_seat"], table["seat_count"]) %>
        <% actions = puzzle_action_summary(scenario) %>
        <% difficulty = puzzle_difficulty_label(scenario["difficulty"] || scenario["scenario_id"]) %>

        <div class="puzzle-scenario-header">
          <div class="flex flex-wrap items-center gap-2">
            <span class="puzzle-scenario-tag puzzle-scenario-tag--street"><%= String.capitalize(scenario["street"] || "") %></span>
            <span class={["puzzle-scenario-tag", puzzle_difficulty_class(difficulty)]}><%= difficulty %></span>
          </div>
          <p class="puzzle-scenario-actions"><%= Enum.join(actions, "  →  ") %></p>
        </div>

        <div class="p-1 sm:p-2">
          <div class="border-white/10 bg-[#2C1320] rounded-2xl border p-1 sm:p-2">
            <div class="aspect-square max-w-[640px] relative mx-auto w-full overflow-hidden" aria-label={"Poker table · #{table["players_in_hand"]} players in hand"}>
              <img src={~p"/images/poker/tables/poker_table1.png"} alt="" class="pointer-events-none absolute inset-0 h-full w-full select-none object-contain" />

              <div class="puzzle-table-marker left-[8%] top-[57%] absolute z-20" aria-label={"Effective stack: #{amount(scenario["effective_stack_bb"])} big blinds"}>
                <span>EFF</span><strong><%= amount(scenario["effective_stack_bb"]) %> BB</strong>
              </div>

              <div
                class="puzzle-table-marker right-[8%] top-[57%] absolute z-20"
                aria-label={"To call: #{amount(get_in(scenario, ["action_state", "amount_to_call_bb"]) || 0)} big blinds"}
              >
                <span>CALL</span><strong><%= amount(get_in(scenario, ["action_state", "amount_to_call_bb"]) || 0) %> BB</strong>
              </div>

              <div class="puzzle-pot-display top-[55%] absolute inset-x-0 z-20 flex flex-col items-center" role="img" aria-label={"Pot: #{amount(scenario["pot"])} big blinds"}>
                <img src={puzzle_pot_image_path(scenario["pot"])} alt="" class="puzzle-pot-art" />
                <strong><%= amount(scenario["pot"]) %> BB</strong>
              </div>

              <div
                :for={opponent <- opponents}
                class={["aspect-square w-[11%] absolute", opponent.cards_position]}
                role="group"
                aria-label={"Opponent at seat #{opponent.seat}, cards face down"}
              >
                <img src={~p"/images/poker/opp_cards.png"} class="h-full w-full object-contain" alt="" aria-hidden="true" />
              </div>

              <div
                class="left-[20%] top-[37.8%] w-[60%] gap-[2.2%] absolute z-10 grid grid-cols-5"
                role="group"
                aria-label={if (scenario["board"] || []) == [], do: "Community cards not dealt yet", else: "Community cards: #{cards_accessible(scenario["board"])}"}
              >
                <.playing_card :for={card <- scenario["board"] || []} card={card} />
              </div>

              <div
                class="left-[41%] top-[70%] w-[18%] gap-[2%] absolute z-10 grid grid-cols-2"
                role="group"
                aria-label={"Hero · #{position_label(hero["position"])} · #{cards_accessible(hero["hole_cards"])}"}
              >
                <.playing_card :for={card <- hero["hole_cards"] || []} card={card} />
              </div>

              <span
                :if={dealer}
                class={[
                  "aspect-square w-[5.5%] text-[9px] absolute z-20 flex items-center justify-center rounded-full border border-amber-900 bg-amber-300 font-black text-amber-950 shadow-md sm:text-xs",
                  dealer.position
                ]}
                role="img"
                aria-label={if dealer.hero?, do: "Dealer button · Hero", else: "Dealer button · opponent at seat #{dealer.seat}"}
              >
                D
              </span>

              <div class="puzzle-table-marker top-[88%] absolute left-1/2 z-20 -translate-x-1/2" aria-label={"Your stack: #{amount(hero["remaining_stack_bb"])} big blinds"}>
                <span>YOU</span><strong><%= amount(hero["remaining_stack_bb"]) %> BB</strong>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end

  attr :card, :string, required: true

  defp playing_card(assigns) do
    ~H"""
    <span
      class="shadow-slate-950/20 aspect-[2/3] rounded-[7px] relative block w-full overflow-hidden border border-slate-300 bg-white font-bold shadow-md sm:rounded-lg"
      role="img"
      aria-label={card_accessible(@card)}
    >
      <span class={["left-[7%] top-[5%] absolute flex flex-col items-center leading-none", suit_text_color(@card)]}>
        <span class="text-[9px] sm:text-xs"><%= rank_label(@card) %></span>
      </span>
      <span :if={face_card?(@card)} class={["absolute inset-0 flex items-center justify-center text-xl opacity-20 sm:text-2xl", suit_text_color(@card)]}>
        <%= rank_label(@card) %>
      </span>
      <.suit_image card={@card} class={["absolute left-1/2 top-1/2 h-[60%] w-auto max-w-[60%] -translate-x-1/2 -translate-y-1/2 object-contain", suit_text_color(@card)]} />
      <span class={["bottom-[5%] right-[7%] absolute flex rotate-180 flex-col items-center leading-none", suit_text_color(@card)]}>
        <span class="text-[9px] sm:text-xs"><%= rank_label(@card) %></span>
      </span>
    </span>
    """
  end

  attr :card, :string, required: true
  attr :class, :any, default: nil

  defp suit_image(assigns) do
    ~H"""
    <img src={suit_image_path(@card)} class={@class} alt="" aria-hidden="true" />
    """
  end

  attr :selected, StepOption, default: nil
  attr :options, :list, required: true
  attr :scenario, :map, default: nil

  def feedback_option(assigns) do
    ~H"""
    <div :if={@selected} class="w-full" role="alert" aria-live="polite">
      <div class="flex items-start gap-3">
        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-white">
          <.icon
            name={if(@selected.correct?, do: "tabler-checks", else: "tabler-book-2")}
            class={["h-5 w-5", @selected.correct? && "text-teal-700", not @selected.correct? && "text-amber-700"]}
          />
        </div>
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2">
            <h3 class="font-bold"><%= feedback_heading(@selected) %></h3>
            <span :if={is_integer(@selected.score)} class="bg-[#2C1320] rounded-full px-2 py-1 text-xs font-semibold text-white">
              <%= @selected.score_label %> · <%= @selected.score %>/100
            </span>
          </div>
          <h4 :if={@selected.feedback} class="mt-1 text-sm leading-5"><%= @selected.feedback %></h4>

          <div :if={@scenario} class="border-[#8797AF] bg-[#56667A] mt-3 rounded-xl border p-3 text-sm text-white">
            <p class="font-semibold text-white">Evidence and takeaway</p>
            <p class="mt-1 leading-5"><%= evidence_summary(@scenario) %></p>
            <p class="mt-1 leading-5">Use the stated assumptions and the information available before the decision. This score reflects a learning rubric, not a solver result.</p>
          </div>

          <details :if={length(@options) > 1} class="border-[#8797AF] bg-[#56667A] mt-3 rounded-xl border p-3 text-sm text-white">
            <summary class="cursor-pointer font-semibold text-white">See the other choices</summary>
            <ul class="mt-2 space-y-2">
              <li :for={option <- @options} :if={option.id != @selected.id} class="border-t border-gray-200 pt-2">
                <p class="font-semibold"><%= option.title %><span :if={is_integer(option.score)}> · <%= option.score_label %> (<%= option.score %>/100)</span></p>
                <p :if={option.feedback} class="mt-1 leading-5"><%= option.feedback %></p>
              </li>
            </ul>
          </details>
        </div>
      </div>
    </div>
    """
  end

  defp feedback_heading(%StepOption{score: nil, correct?: true}), do: dgettext("courses", "Well done!")
  defp feedback_heading(%StepOption{score: nil, correct?: false}), do: dgettext("courses", "That's incorrect.")
  defp feedback_heading(%StepOption{score: score}) when score >= 100, do: "Strong choice"
  defp feedback_heading(%StepOption{score: score}) when score >= 70, do: "Reasonable alternative"
  defp feedback_heading(%StepOption{score: score}) when score >= 30, do: "Review this idea"
  defp feedback_heading(%StepOption{}), do: "Try a different way of thinking"

  defp evidence_summary(scenario) do
    hero = scenario["hero"] || %{}
    action_state = scenario["action_state"] || %{}
    cards = Enum.map_join(hero["hole_cards"] || [], ", ", &card_accessible/1)
    board = Enum.map_join(scenario["board"] || [], ", ", &card_accessible/1)
    call_amount = Map.get(action_state, "amount_to_call_bb", 0)

    "Hero has #{cards}; board: #{if(board == "", do: "not dealt", else: board)}. Pot #{amount(scenario["pot"])} BB, to call #{amount(call_amount)} BB."
  end

  defp cards_accessible(cards), do: Enum.map_join(cards || [], ", ", &card_accessible/1)

  defp card_accessible(card), do: "#{rank_name(card)} of #{suit_name(card)}"

  defp amount(value) when is_integer(value), do: Integer.to_string(value)
  defp amount(value) when is_float(value), do: value |> :erlang.float_to_binary(decimals: 2) |> String.trim_trailing("0") |> String.trim_trailing(".")
  defp amount(_value), do: "0"

  defp puzzle_difficulty_label("medium"), do: "Medium"
  defp puzzle_difficulty_label("hard"), do: "Hard"
  defp puzzle_difficulty_label(id) when id in ["puzzle-preflop-2", "puzzle-flop-2", "puzzle-turn-2", "puzzle-river-2", "puzzle-showdown-2"], do: "Medium"
  defp puzzle_difficulty_label(_difficulty), do: "Easy"

  defp puzzle_difficulty_class("Medium"), do: "puzzle-scenario-tag--medium"
  defp puzzle_difficulty_class("Hard"), do: "puzzle-scenario-tag--hard"
  defp puzzle_difficulty_class(_difficulty), do: "puzzle-scenario-tag--easy"

  defp puzzle_action_summary(%{"action_history" => [first | _]} = scenario) do
    if List.last(scenario["action_history"]) == "Your turn" do
      scenario["action_history"]
    else
      summarize_legacy_action(first, scenario)
    end
  end

  defp puzzle_action_summary(_scenario), do: ["Your turn"]

  defp summarize_legacy_action(history, scenario) do
    street_bet = get_in(scenario, ["action_state", "street_bet_bb"]) || 0

    cond do
      String.contains?(history, "small and big blinds") -> ["Blinds posted", "Your turn"]
      String.contains?(history, "flop checked through") -> ["You call preflop", "Flop checks", "Opponent bets #{amount(street_bet)} BB", "Your turn"]
      String.contains?(history, "button raised") -> ["Button raises", "You call", "Your turn"]
      String.contains?(history, "raised to") -> ["Opponent raises to #{amount(street_bet)} BB", "Your turn"]
      String.contains?(history, "opponent checked") -> ["You raise", "Opponent calls", "Opponent checks", "Your turn"]
      String.contains?(history, "opponent bet") -> ["You raise", "Opponent calls", "Opponent bets #{amount(street_bet)} BB", "Your turn"]
      true -> ["Your turn"]
    end
  end

  defp puzzle_pot_image_path(pot) when is_number(pot) and pot < 30, do: ~p"/images/poker/pots/small_pot.png"
  defp puzzle_pot_image_path(pot) when is_number(pot) and pot < 80, do: ~p"/images/poker/pots/medium_pot.png"
  defp puzzle_pot_image_path(_pot), do: ~p"/images/poker/pots/large_pot.png"

  defp rank_label(<<rank::binary-size(1), _suit::binary>>), do: if(rank == "T", do: "10", else: rank)
  defp rank_label(_card), do: "?"
  defp face_card?(<<rank::binary-size(1), _suit::binary>>), do: rank in ~w(J Q K)
  defp face_card?(_card), do: false
  defp suit_text_color(<<_rank::binary-size(1), suit::binary-size(1)>>) when suit in ["h", "d"], do: "text-rose-600"
  defp suit_text_color(_card), do: "text-slate-950"

  defp rank_name(<<rank::binary-size(1), _suit::binary>>) do
    %{
      "2" => "Two",
      "3" => "Three",
      "4" => "Four",
      "5" => "Five",
      "6" => "Six",
      "7" => "Seven",
      "8" => "Eight",
      "9" => "Nine",
      "T" => "Ten",
      "J" => "Jack",
      "Q" => "Queen",
      "K" => "King",
      "A" => "Ace"
    }[rank] || "Unknown card"
  end

  defp rank_name(_card), do: "Unknown card"
  defp suit_image_path(<<_rank::binary-size(1), "s">>), do: ~p"/images/poker/suits/spade.png"
  defp suit_image_path(<<_rank::binary-size(1), "h">>), do: ~p"/images/poker/suits/heart.png"
  defp suit_image_path(<<_rank::binary-size(1), "d">>), do: ~p"/images/poker/suits/diamond.png"
  defp suit_image_path(<<_rank::binary-size(1), "c">>), do: ~p"/images/poker/suits/club.png"
  defp suit_image_path(_card), do: ~p"/images/poker/suits/spade.png"
  defp suit_name(<<_rank::binary-size(1), "s">>), do: "spades"
  defp suit_name(<<_rank::binary-size(1), "h">>), do: "hearts"
  defp suit_name(<<_rank::binary-size(1), "d">>), do: "diamonds"
  defp suit_name(<<_rank::binary-size(1), "c">>), do: "clubs"
  defp suit_name(_card), do: "unknown suit"

  defp opponent_seats(hero_seat, 6) when is_integer(hero_seat) and hero_seat in 1..6 do
    1..6
    |> Enum.reject(&(&1 == hero_seat))
    |> Enum.map(fn seat ->
      offset = Integer.mod(seat - hero_seat, 6)
      Map.put(seat_layout(offset), :seat, seat)
    end)
  end

  defp opponent_seats(_hero_seat, _seat_count), do: []

  defp dealer_seat(hero_seat, button_seat, 6) when is_integer(hero_seat) and hero_seat in 1..6 and is_integer(button_seat) and button_seat in 1..6 do
    offset = Integer.mod(button_seat - hero_seat, 6)
    layout = seat_layout(offset)
    %{position: layout.dealer_position, hero?: offset == 0, seat: button_seat}
  end

  defp dealer_seat(_hero_seat, _button_seat, _seat_count), do: nil

  defp seat_layout(0), do: %{dealer_position: "left-[33%] top-[71%]"}
  defp seat_layout(1), do: %{cards_position: "left-[11%] top-[65%]", dealer_position: "left-[5%] top-[68%]"}
  defp seat_layout(2), do: %{cards_position: "left-[15%] top-[17%]", dealer_position: "left-[8%] top-[23%]"}
  defp seat_layout(3), do: %{cards_position: "left-[43%] top-[17%]", dealer_position: "left-[58%] top-[23%]"}
  defp seat_layout(4), do: %{cards_position: "left-[69%] top-[17%]", dealer_position: "left-[86%] top-[23%]"}
  defp seat_layout(5), do: %{cards_position: "left-[75%] top-[65%]", dealer_position: "left-[69%] top-[68%]"}

  defp position_label(nil), do: "unknown position"
  defp position_label(position), do: position |> String.replace("_", " ") |> String.capitalize()
end
