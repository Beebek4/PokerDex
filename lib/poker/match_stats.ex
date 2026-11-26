defmodule Zoonk.Poker.MatchStats do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User
  alias Zoonk.Poker.Match

  schema "poker_match_stats" do
    field :mode, :string
    field :hands_played, :integer, default: 0
    field :metrics, :map, default: %{}

    belongs_to :match, Match
    belongs_to :user, User
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(stats, attrs) do
    stats
    |> cast(attrs, [:match_id, :user_id, :mode, :hands_played, :metrics])
    |> validate_required([:match_id, :user_id, :mode, :hands_played, :metrics])
    |> validate_inclusion(:mode, ~w(heads_up tournament))
    |> validate_number(:hands_played, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:match_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:match_id)
  end
end
