defmodule Zoonk.Poker.OpponentStats do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User

  schema "poker_opponent_stats" do
    field :opponent_id, :string
    field :mode, :string
    field :hands_seen, :integer, default: 0
    field :vpip_hands, :integer, default: 0
    field :pfr_hands, :integer, default: 0
    field :three_bet_opportunities, :integer, default: 0
    field :three_bets, :integer, default: 0
    field :cbet_opportunities, :integer, default: 0
    field :cbets, :integer, default: 0
    field :postflop_actions, :integer, default: 0
    field :aggressive_actions, :integer, default: 0
    field :postflop_calls, :integer, default: 0
    field :facing_bet_decisions, :integer, default: 0
    field :calls_when_facing_bet, :integer, default: 0
    field :folds_when_facing_bet, :integer, default: 0
    field :showdowns, :integer, default: 0
    field :saw_flop_hands, :integer, default: 0
    field :wtsd_showdowns, :integer, default: 0

    belongs_to :user, User
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(stats, attrs) do
    stats
    |> cast(attrs, [
      :user_id,
      :opponent_id,
      :mode,
      :hands_seen,
      :vpip_hands,
      :pfr_hands,
      :three_bet_opportunities,
      :three_bets,
      :cbet_opportunities,
      :cbets,
      :postflop_actions,
      :aggressive_actions,
      :postflop_calls,
      :facing_bet_decisions,
      :calls_when_facing_bet,
      :folds_when_facing_bet,
      :saw_flop_hands,
      :wtsd_showdowns,
      :showdowns
    ])
    |> validate_required([:user_id, :opponent_id, :mode])
    |> validate_inclusion(:mode, ~w(heads_up tournament))
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :opponent_id, :mode])
  end
end
