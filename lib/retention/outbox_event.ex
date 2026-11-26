defmodule Zoonk.Retention.OutboxEvent do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User

  @primary_key {:id, :id, autogenerate: true}
  schema "retention_outbox_events" do
    field :event_id, Ecto.UUID
    field :event_name, :string
    field :schema_version, :integer, default: 1
    field :payload, :map, default: %{}
    field :occurred_at, :utc_datetime_usec
    field :published_at, :utc_datetime_usec
    field :locked_at, :utc_datetime_usec
    field :attempts, :integer, default: 0
    belongs_to :user, User
    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_id, :user_id, :event_name, :schema_version, :payload, :occurred_at])
    |> validate_required([:event_id, :user_id, :event_name, :schema_version, :payload, :occurred_at])
    |> unique_constraint(:event_id)
    |> foreign_key_constraint(:user_id)
  end
end
