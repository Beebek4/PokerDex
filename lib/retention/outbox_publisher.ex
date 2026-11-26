defmodule Zoonk.Retention.OutboxPublisher do
  @moduledoc "Publishes claimed PostgreSQL outbox rows to Kafka with at-least-once delivery."
  use Oban.Worker, queue: :retention, max_attempts: 10

  alias Zoonk.Retention

  require Logger

  @client :zoonk_retention_kafka
  @topic "pokerdex.retention.v1"

  @impl Oban.Worker
  def perform(_job) do
    Retention.cleanup_published()

    if Retention.enabled?() do
      with {:ok, events} <- Retention.outbox_batch(),
           :ok <- publish(events) do
        Retention.mark_published(Enum.map(events, & &1.id))
        :ok
      else
        {:error, reason} = error ->
          Logger.warning("Retention outbox publish failed: #{inspect(reason)}")
          error
      end
    else
      :ok
    end
  end

  defp publish([]), do: :ok

  defp publish(events) do
    hosts = Retention.kafka_hosts()

    with :ok <- ensure_client(hosts),
         :ok <- ensure_topic_producer() do
      results =
        Enum.reduce_while(events, {:ok, []}, fn event, {:ok, refs} ->
          public_event = Retention.public_event(event, event.user_id)
          payload = Jason.encode!(public_event)

          case :brod.produce(@client, @topic, :hash, public_event.subject_id, payload) do
            {:ok, ref} -> {:cont, {:ok, [ref | refs]}}
            :ok -> {:cont, {:ok, refs}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      case results do
        {:ok, refs} ->
          case await_acks(refs) do
            :ok ->
              :ok

            {:error, reason} ->
              Retention.release_claim(Enum.map(events, & &1.id))
              {:error, reason}
          end

        {:error, reason} ->
          Retention.release_claim(Enum.map(events, & &1.id))
          {:error, reason}
      end
    else
      {:error, reason} ->
        Retention.release_claim(Enum.map(events, & &1.id))
        {:error, reason}
    end
  end

  defp await_acks(refs) do
    Enum.reduce_while(refs, :ok, fn ref, :ok ->
      case :brod.sync_produce_request(ref, 15_000) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ensure_client(hosts) do
    case :brod.start_client(hosts, @client, auto_start_producers: true) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_topic_producer do
    case :brod.start_producer(@client, @topic, []) do
      :ok -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
