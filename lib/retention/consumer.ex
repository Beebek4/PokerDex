defmodule Zoonk.Retention.Consumer do
  @moduledoc "Consumes the retention topic and writes bounded batches to ClickHouse."
  use Broadway

  alias Broadway.Message
  alias Zoonk.Retention.ClickHouse
  alias Zoonk.Retention.DeadLetter

  require Logger

  @topic "pokerdex.retention.v1"

  def start_link(_opts) do
    hosts = Zoonk.Retention.kafka_hosts()

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayKafka.Producer, [hosts: hosts, group_id: "pokerdex-retention-clickhouse-v1", topics: [@topic], offset_reset_policy: :earliest]},
        concurrency: 1
      ],
      processors: [default: [concurrency: 4]],
      batchers: [default: [batch_size: 250, batch_timeout: 1_000, concurrency: 2]]
    )
  end

  @impl Broadway
  def handle_message(_processor, message, _context) do
    case Jason.decode(message.data) do
      {:ok, event} ->
        if Zoonk.Retention.valid_public_event?(event) do
          Message.update_data(message, fn _ -> event end)
        else
          Message.failed(message, :invalid_event_schema)
        end

      {:error, reason} ->
        Message.failed(message, {:invalid_event, reason})
    end
  end

  @impl Broadway
  def handle_batch(_batcher, messages, _batch_info, _context) do
    case ClickHouse.write_batch(messages) do
      :ok -> messages
      {:error, reason} -> Enum.map(messages, &Message.failed(&1, {:clickhouse_write_failed, reason}))
    end
  end

  @impl Broadway
  def handle_failed(messages, _context) do
    Enum.each(messages, fn message ->
      event_id = if is_map(message.data), do: Map.get(message.data, "event_id")
      Logger.error("Retention event failed downstream; sending to dead-letter topic", event_id: event_id)
      DeadLetter.publish(message)
    end)

    messages
  end
end
