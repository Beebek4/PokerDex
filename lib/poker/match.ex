defmodule Zoonk.Poker.Match do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User

  schema "poker_matches" do
    field :opponent_id, :string
    field :difficulty, :string
    field :status, :string, default: "active"
    field :result, :string
    field :buy_in, :integer, default: 0
    field :payout, :integer, default: 0
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    belongs_to :user, User
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(match, attrs) do
    match
    |> cast(attrs, [:opponent_id, :difficulty, :status, :result, :buy_in, :payout, :started_at, :completed_at, :user_id])
    |> validate_required([:opponent_id, :difficulty, :status, :buy_in, :payout, :started_at, :user_id])
    |> validate_inclusion(:status, ~w(active completed abandoned))
    |> validate_inclusion(:difficulty, ~w(easy standard hard))
    |> validate_inclusion(:result, [nil, "won", "lost", "tied"])
    |> validate_number(:buy_in, greater_than_or_equal_to: 0)
    |> validate_number(:payout, greater_than_or_equal_to: 0)
  end
end
