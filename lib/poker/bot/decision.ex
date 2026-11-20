defmodule Zoonk.Poker.Bot.Decision do
  @moduledoc "A bot action and a stable reason code for logs and future coaching."
  @enforce_keys [:action, :amount, :reason]
  defstruct [:action, :amount, :reason]

  @type t :: %__MODULE__{action: String.t(), amount: number(), reason: atom()}
end
