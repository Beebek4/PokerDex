defmodule Zoonk.Poker.Native.GameView do
  @moduledoc false

  @type t :: %__MODULE__{
          round: String.t(),
          acting_player: non_neg_integer(),
          human_action_enabled: boolean(),
          pot: float(),
          to_call: float(),
          min_raise: float(),
          max_raise: float(),
          hero_stack: float(),
          bot_stack: float(),
          winner: non_neg_integer() | nil,
          is_tie: boolean(),
          hero_cards: [String.t()],
          bot_cards: [String.t()],
          board: [String.t()],
          best_five: [String.t()]
        }

  defstruct [
    :round,
    :acting_player,
    :human_action_enabled,
    :pot,
    :to_call,
    :min_raise,
    :max_raise,
    :hero_stack,
    :bot_stack,
    :winner,
    :is_tie,
    :hero_cards,
    :bot_cards,
    :board,
    :best_five
  ]
end

defmodule Zoonk.Poker.Native do
  @moduledoc """
  Temporary integration spike for evaluating the `rs-poker` Rust crate.

  This module is isolated from the Play UI and existing puzzle rules. The current
  human-turn API covers a simple heads-up check/call hand through showdown;
  it is not production gameplay.
  """

  use Rustler, otp_app: :zoonk, crate: :poker_native

  alias Zoonk.Poker.Native.GameView

  @doc "Ranks a Hold'em hand represented as a compact card string, such as `AsKsQsJsTs`."
  @spec rank_hand(String.t()) :: String.t()
  def rank_hand(_cards), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Runs a tiny heads-up simulation to check the `rs-poker` arena API through the NIF."
  @spec simulate_calling_agents() :: String.t()
  def simulate_calling_agents, do: :erlang.nif_error(:nif_not_loaded)

  @doc "Starts a temporary heads-up hand and returns its NIF-backed session and view."
  @spec start_human_hand() :: {term(), GameView.t()}
  def start_human_hand, do: start_human_hand(100.0, 100.0)

  @spec start_human_hand(float(), float()) :: {term(), GameView.t()}
  def start_human_hand(_hero_total, _bot_total), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Applies a fold, check, call, or raise and advances the call/check bot through the hand."
  @spec human_action(term(), String.t(), float()) :: GameView.t()
  def human_action(_session, _action, _amount), do: :erlang.nif_error(:nif_not_loaded)
end
