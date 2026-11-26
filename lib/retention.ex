defmodule Zoonk.Retention do
  @moduledoc "Consent-aware product study event intake and transactional outbox."

  import Ecto.Query

  alias Zoonk.Accounts.User
  alias Zoonk.Poker.Match
  alias Zoonk.Repo
  alias Zoonk.Retention.OutboxEvent

  @event_names ~w(ui.interaction puzzle.started puzzle.answered opponent.profile_opened)
  @published_event_names @event_names ++ ~w(match.completed privacy.user_erased)
  @properties ~w(screen control action street difficulty result opponent_id)
  @screens ~w(play progress practice theory)
  @controls ~w(start_match player_action raise_more next_hand profile_open answer open_section nav)
  @actions ~w(fold call check raise)
  @streets ~w(preflop flop turn river showdown)
  @difficulties ~w(easy medium hard beginner intermediate advanced)
  @results ~w(correct incorrect won lost tied)

  @doc "Stores allowlisted, consented events. Payloads cannot contain free text or identifiers."
  def track_batch(%User{retention_study_opt_in: true} = user, events) when is_list(events) do
    with true <- enabled?() || {:error, :analytics_unavailable},
         :ok <- validate_batch(events) do
      now = DateTime.truncate(DateTime.utc_now(), :microsecond)

      fn ->
        locked_user = Repo.one(from(account in User, where: account.id == ^user.id, lock: "FOR UPDATE"))

        unless locked_user && locked_user.retention_study_opt_in do
          Repo.rollback(:consent_required)
        end

        rows =
          Enum.map(events, fn event ->
            %{
              event_id: event["event_id"] || Ecto.UUID.generate(),
              user_id: user.id,
              event_name: event["event_name"],
              schema_version: 1,
              payload:
                Map.put(
                  sanitize_properties(event["properties"] || %{}),
                  "_subject_id",
                  pseudonymous_user_id(user.id)
                ),
              occurred_at: now,
              inserted_at: now
            }
          end)

        {count, _} = Repo.insert_all(OutboxEvent, rows, on_conflict: :nothing, conflict_target: :event_id)
        if count > 0, do: enqueue_publish_job()
        count
      end
      |> Repo.transaction()
      |> case do
        {:ok, count} -> {:ok, count}
        error -> error
      end
    end
  end

  def track_batch(%User{}, _events), do: {:error, :consent_required}
  def track_batch(_user, _events), do: {:error, :authentication_required}

  @doc "Records a server-authoritative match result only for users who opted in."
  def track_match_completion(user_id, match_id, summary, result) do
    user = Repo.one!(from(account in User, where: account.id == ^user_id, lock: "FOR UPDATE"))

    if user.retention_study_opt_in and enabled?() do
      match = Repo.get!(Match, match_id)
      now = DateTime.truncate(DateTime.utc_now(), :microsecond)

      Repo.insert_all(OutboxEvent, [
        %{
          event_id: Ecto.UUID.generate(),
          user_id: user_id,
          event_name: "match.completed",
          schema_version: 1,
          payload: %{
            "_subject_id" => pseudonymous_user_id(user_id),
            "mode" => summary.mode,
            "result" => result,
            "opponent_id" => match.opponent_id,
            "hands_played" => summary.hands_played
          },
          occurred_at: now,
          inserted_at: now
        }
      ])

      enqueue_publish_job()
    end

    :ok
  end

  @doc "Queues a pseudonymous erasure marker before the account's outbox rows are detached."
  def track_user_erasure(%User{retention_study_opt_in: true} = user) do
    Repo.one!(from(account in User, where: account.id == ^user.id, lock: "FOR UPDATE"))
    Repo.delete_all(from(event in OutboxEvent, where: event.user_id == ^user.id))

    if enabled?() do
      now = DateTime.truncate(DateTime.utc_now(), :microsecond)

      Repo.insert_all(OutboxEvent, [
        %{
          event_id: Ecto.UUID.generate(),
          user_id: nil,
          event_name: "privacy.user_erased",
          schema_version: 1,
          payload: %{"_subject_id" => pseudonymous_user_id(user.id)},
          occurred_at: now,
          inserted_at: now
        }
      ])

      enqueue_publish_job()
    end

    :ok
  end

  def track_user_erasure(_user), do: :ok

  def outbox_batch(limit \\ 100) do
    now = DateTime.truncate(DateTime.utc_now(), :microsecond)
    lease_expired_at = DateTime.add(now, -120, :second)

    Repo.transaction(fn ->
      events =
        Repo.all(
          from(event in OutboxEvent,
            where:
              is_nil(event.published_at) and
                (is_nil(event.locked_at) or event.locked_at < ^lease_expired_at),
            order_by: [asc: event.inserted_at],
            limit: ^limit,
            lock: "FOR UPDATE SKIP LOCKED"
          )
        )

      Enum.each(events, fn event ->
        Repo.update_all(from(row in OutboxEvent, where: row.id == ^event.id),
          set: [locked_at: now],
          inc: [attempts: 1]
        )
      end)

      events
    end)
  end

  def mark_published(ids) do
    now = DateTime.truncate(DateTime.utc_now(), :microsecond)

    Repo.update_all(from(event in OutboxEvent, where: event.id in ^ids),
      set: [published_at: now, locked_at: nil]
    )
  end

  def release_claim(ids), do: Repo.update_all(from(event in OutboxEvent, where: event.id in ^ids), set: [locked_at: nil])

  def cleanup_published(retention_days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -retention_days * 86_400, :second)

    Repo.delete_all(
      from(event in OutboxEvent,
        where: not is_nil(event.published_at) and event.published_at < ^cutoff
      )
    )
  end

  def kafka_hosts do
    case System.get_env("KAFKA_BROKERS") do
      nil ->
        []

      "" ->
        []

      value ->
        value
        |> String.split(",", trim: true)
        |> Enum.map(fn host_port ->
          [host, port] = String.split(host_port, ":", parts: 2)
          {host, String.to_integer(port)}
        end)
    end
  end

  def enabled?, do: kafka_hosts() != []

  def public_event(event, user_id) do
    %{
      event_id: event.event_id,
      subject_id: Map.get(event.payload, "_subject_id") || pseudonymous_user_id(user_id),
      event_name: event.event_name,
      schema_version: event.schema_version,
      properties: Map.delete(event.payload, "_subject_id"),
      occurred_at: DateTime.to_iso8601(event.occurred_at)
    }
  end

  def valid_public_event?(event) when is_map(event) do
    event |> Map.keys() |> Enum.sort() == ~w(event_id event_name occurred_at properties schema_version subject_id) and
      event["event_name"] in @published_event_names and event["schema_version"] == 1 and
      valid_subject_id?(event["subject_id"]) and valid_event_id?(event["event_id"]) and
      valid_timestamp?(event["occurred_at"]) and valid_public_properties?(event["event_name"], event["properties"])
  end

  def valid_public_event?(_event), do: false

  defp validate_batch(events) when length(events) <= 50 do
    cond do
      events == [] -> {:error, :empty_batch}
      Enum.all?(events, &valid_event?/1) -> :ok
      true -> {:error, :invalid_event}
    end
  end

  defp validate_batch(_events), do: {:error, :batch_too_large}

  defp valid_event?(%{"event_name" => name} = event) when name in @event_names do
    props = event["properties"] || %{}

    Enum.all?(Map.keys(event), &(&1 in ["event_id", "event_name", "properties"])) and
      valid_optional_event_id?(event["event_id"]) and is_map(props) and Enum.all?(Map.keys(props), &(&1 in @properties)) and
      Enum.all?(props, fn {key, value} -> valid_property?(key, value) end)
  end

  defp valid_event?(_event), do: false

  defp valid_optional_event_id?(nil), do: true
  defp valid_optional_event_id?(event_id), do: is_binary(event_id) and match?({:ok, _}, Ecto.UUID.cast(event_id))

  defp valid_property?(key, value) when key in @properties do
    allowed =
      case key do
        "screen" -> @screens
        "control" -> @controls
        "action" -> @actions
        "street" -> @streets
        "difficulty" -> @difficulties
        "result" -> @results
        "opponent_id" -> ~w(teddy grandpa mum brother sister dad house-tournament)
      end

    value in allowed
  end

  defp sanitize_properties(props), do: Map.take(props, @properties)

  defp valid_subject_id?(value), do: is_binary(value) and Regex.match?(~r/^[0-9a-f]{64}$/, value)

  defp valid_event_id?(value), do: match?({:ok, _}, Ecto.UUID.cast(value))

  defp valid_timestamp?(value), do: is_binary(value) and match?({:ok, _, _}, DateTime.from_iso8601(value))

  defp valid_public_properties?("privacy.user_erased", properties), do: properties == %{}

  defp valid_public_properties?("match.completed", properties) when is_map(properties) do
    properties |> Map.keys() |> Enum.sort() == ~w(hands_played mode opponent_id result) and
      properties["mode"] in ~w(heads_up tournament) and properties["result"] in @results and
      properties["opponent_id"] in ~w(teddy grandpa mum brother sister dad house-tournament) and
      is_integer(properties["hands_played"]) and properties["hands_played"] >= 0 and properties["hands_played"] <= 100_000
  end

  defp valid_public_properties?(event_name, properties) when event_name in @event_names and is_map(properties) do
    properties |> Map.keys() |> Enum.all?(&(&1 in @properties)) and
      Enum.all?(properties, fn {key, value} -> valid_property?(key, value) end)
  end

  defp valid_public_properties?(_event_name, _properties), do: false

  defp enqueue_publish_job do
    if enabled?() and Application.get_env(:zoonk, :app_env) != :test do
      Oban.insert!(Zoonk.Retention.OutboxPublisher.new(%{}))
    end
  end

  defp pseudonymous_user_id(user_id) do
    secret = Application.fetch_env!(:zoonk, ZoonkWeb.Endpoint)[:secret_key_base]
    :hmac |> :crypto.mac(:sha256, secret, to_string(user_id)) |> Base.encode16(case: :lower)
  end
end
