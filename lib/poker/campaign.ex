defmodule Zoonk.Poker.Campaign do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User

  schema "poker_campaigns" do
    field :cash, :integer, default: 1000
    field :respect, :integer, default: 0
    field :house_bracelet_earned_at, :utc_datetime_usec

    belongs_to :user, User
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:cash, :respect, :house_bracelet_earned_at, :user_id])
    |> validate_required([:cash, :respect, :user_id])
    |> validate_number(:cash, greater_than_or_equal_to: 0)
    |> validate_number(:respect, greater_than_or_equal_to: 0)
    |> unique_constraint(:user_id)
  end
end
