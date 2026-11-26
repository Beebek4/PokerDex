defmodule Zoonk.RetentionTest do
  use Zoonk.DataCase, async: false

  import Zoonk.Fixtures.Accounts

  alias Zoonk.Accounts
  alias Zoonk.Accounts.User
  alias Zoonk.Poker.Campaigns
  alias Zoonk.Poker.Opponents
  alias Zoonk.Poker.Stats
  alias Zoonk.Repo
  alias Zoonk.Retention
  alias Zoonk.Retention.OutboxEvent

  setup do
    previous_brokers = System.get_env("KAFKA_BROKERS")
    System.put_env("KAFKA_BROKERS", "localhost:9092")

    on_exit(fn ->
      if previous_brokers, do: System.put_env("KAFKA_BROKERS", previous_brokers), else: System.delete_env("KAFKA_BROKERS")
    end)

    :ok
  end

  test "does not collect study events until the downstream pipeline is configured" do
    user = user_fixture() |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()
    previous_brokers = System.get_env("KAFKA_BROKERS")
    System.delete_env("KAFKA_BROKERS")

    try do
      assert {:error, :analytics_unavailable} =
               Retention.track_batch(user, [%{"event_name" => "ui.interaction", "properties" => %{}}])

      assert Repo.all(OutboxEvent) == []
    after
      if previous_brokers, do: System.put_env("KAFKA_BROKERS", previous_brokers), else: System.delete_env("KAFKA_BROKERS")
    end
  end

  test "parses Kafka broker hosts in the format BroadwayKafka accepts" do
    assert Retention.kafka_hosts() == [{"localhost", 9092}]
  end

  test "event batches require opt-in and reject free-form or unapproved fields" do
    user = user_fixture()
    event = %{"event_name" => "ui.interaction", "properties" => %{"screen" => "play", "control" => "player_action", "action" => "call"}}

    assert {:error, :consent_required} = Retention.track_batch(user, [event])

    user = user |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()

    assert {:error, :invalid_event} =
             Retention.track_batch(user, [%{"event_name" => "ui.interaction", "properties" => %{"email" => "private@example.com"}}])

    assert {:ok, 1} = Retention.track_batch(user, [event])

    assert [%OutboxEvent{event_name: "ui.interaction", payload: %{"screen" => "play", "control" => "player_action", "action" => "call"}}] =
             Repo.all(OutboxEvent)

    outbox_event = Repo.one!(OutboxEvent)
    public_event = outbox_event |> Retention.public_event(user.id) |> Jason.encode!() |> Jason.decode!()
    assert Retention.valid_public_event?(public_event)
    refute Map.has_key?(public_event["properties"], "_subject_id")

    refute user_fixture().retention_study_opt_in
  end

  test "event batch has a hard size limit" do
    user = user_fixture() |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()
    event = %{"event_name" => "ui.interaction", "properties" => %{}}

    assert {:error, :batch_too_large} = Retention.track_batch(user, List.duplicate(event, 51))
  end

  test "client event IDs make retried batches idempotent" do
    user = user_fixture() |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()

    event = %{
      "event_id" => Ecto.UUID.generate(),
      "event_name" => "ui.interaction",
      "properties" => %{"screen" => "play", "control" => "nav"}
    }

    assert {:ok, 1} = Retention.track_batch(user, [event])
    assert {:ok, 0} = Retention.track_batch(user, [event])
    assert length(Repo.all(OutboxEvent)) == 1
  end

  test "match result and opt-in event commit with the completed match" do
    user = user_fixture() |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()
    {:ok, {_campaign, match}} = Campaigns.start_match(user.id, Opponents.get("teddy"), "easy")

    assert {:ok, _result} = Campaigns.finish_match(user.id, match.id, "won", Stats.new_match(:heads_up))

    assert [%OutboxEvent{event_name: "match.completed"} = outbox_event] = Repo.all(OutboxEvent)
    public_event = outbox_event |> Retention.public_event(user.id) |> Jason.encode!() |> Jason.decode!()
    assert Retention.valid_public_event?(public_event)
  end

  test "outbox claims can retry safely and published rows are pruned" do
    user = user_fixture() |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()
    event = %{"event_name" => "ui.interaction", "properties" => %{"screen" => "play", "control" => "nav"}}

    assert {:ok, 1} = Retention.track_batch(user, [event])
    assert {:ok, [%OutboxEvent{attempts: 0} = first]} = Retention.outbox_batch(1)
    assert {1, nil} = Retention.release_claim([first.id])
    assert {:ok, [%OutboxEvent{attempts: 1} = retry]} = Retention.outbox_batch(1)
    assert retry.id == first.id

    assert {1, nil} = Retention.mark_published([retry.id])
    assert {1, nil} = Retention.cleanup_published(0)
    assert Repo.all(OutboxEvent) == []
  end

  test "account deletion removes pending opt-in events when no analytics broker is configured" do
    previous_brokers = System.get_env("KAFKA_BROKERS")

    try do
      user = user_fixture() |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()
      event = %{"event_name" => "ui.interaction", "properties" => %{"screen" => "play", "control" => "nav"}}
      assert {:ok, 1} = Retention.track_batch(user, [event])
      System.put_env("KAFKA_BROKERS", "")

      assert {:ok, deleted_user} = Accounts.delete_user(user)
      assert deleted_user.id == user.id
      assert Repo.get(User, user.id) == nil
      assert Repo.all(OutboxEvent) == []
    after
      if previous_brokers, do: System.put_env("KAFKA_BROKERS", previous_brokers), else: System.delete_env("KAFKA_BROKERS")
    end
  end

  test "withdrawing opt-in clears pending events when the stream is offline" do
    previous_brokers = System.get_env("KAFKA_BROKERS")

    try do
      user = user_fixture() |> Ecto.Changeset.change(retention_study_opt_in: true) |> Repo.update!()
      event = %{"event_name" => "ui.interaction", "properties" => %{"screen" => "play", "control" => "nav"}}
      assert {:ok, 1} = Retention.track_batch(user, [event])
      System.put_env("KAFKA_BROKERS", "")

      assert {:ok, %User{retention_study_opt_in: false}} = Accounts.update_user_settings(user, %{retention_study_opt_in: false})
      System.put_env("KAFKA_BROKERS", previous_brokers || "localhost:9092")
      assert {:error, :consent_required} = Retention.track_batch(user, [event])
      assert Repo.all(OutboxEvent) == []
    after
      if previous_brokers, do: System.put_env("KAFKA_BROKERS", previous_brokers), else: System.delete_env("KAFKA_BROKERS")
    end
  end
end
