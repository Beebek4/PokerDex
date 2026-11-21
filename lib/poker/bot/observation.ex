defmodule Zoonk.Poker.Bot.Observation do
  @moduledoc "The public table state and only the acting bot's private cards."

  @enforce_keys [:street, :hole_cards, :board, :pot, :stack, :opponent_stack, :to_call, :min_raise, :max_raise]
  defstruct [
    :street,
    :hole_cards,
    :board,
    :pot,
    :stack,
    :opponent_stack,
    :to_call,
    :min_raise,
    :max_raise
  ]

  @type t :: %__MODULE__{
          street: String.t(),
          hole_cards: [String.t()],
          board: [String.t()],
          pot: number(),
          stack: number(),
          opponent_stack: number(),
          to_call: number(),
          min_raise: number(),
          max_raise: number()
        }
end
