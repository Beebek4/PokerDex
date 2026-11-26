defmodule Zoonk.Retention.DeadLetter do
  @moduledoc false
  require Logger

  @client :zoonk_retention_dlq
  @topic "pokerdex.retention.dlq.v1"

  def publish(message) do
    case Zoonk.Retention.kafka_hosts() do
      [] ->
        :ok

      hosts ->
        event_id = if is_map(message.data), do: Map.get(message.data, "event_id")
        event_id = event_id || "unknown"
        record = Jason.encode!(%{event_id: event_id, reason: inspect(message.status)})

        with {:ok, _pid} <- start_client(hosts),
             :ok <- start_producer(),
             :ok <- :brod.produce_sync(@client, @topic, :hash, event_id, record) do
          :ok
        else
          {:error, reason} ->
            Logger.error("Could not persist retention dead-letter event", event_id: event_id, reason: inspect(reason))
            :error
        end
    end
  end

  defp start_client(hosts) do
    case :brod.start_client(hosts, @client, auto_start_producers: true) do
      {:error, {:already_started, _pid}} -> {:ok, self()}
      result -> result
    end
  end

  defp start_producer do
    case :brod.start_producer(@client, @topic, []) do
      {:error, {:already_started, _pid}} -> :ok
      result -> result
    end
  end
end
