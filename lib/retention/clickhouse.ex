defmodule Zoonk.Retention.ClickHouse do
  @moduledoc "Writes already-batched retention events to ClickHouse over its HTTP interface."

  @table "pokerdex.retention_events"

  def write_batch([]), do: :ok

  def write_batch(events) do
    {erasures, regular_events} = Enum.split_with(events, &(&1.data["event_name"] == "privacy.user_erased"))

    with :ok <- insert_events(regular_events) do
      delete_erased_subjects(erasures)
    end
  end

  defp insert_events([]), do: :ok

  defp insert_events(events) do
    body =
      Enum.map_join(events, "\n", fn message ->
        event = Map.update!(message.data, "properties", &Jason.encode!/1)
        Jason.encode!(event) <> "\n"
      end)

    request("INSERT INTO #{@table} FORMAT JSONEachRow", body)
  end

  defp delete_erased_subjects(events) do
    Enum.reduce_while(events, :ok, fn message, :ok ->
      subject_id = message.data["subject_id"]

      if is_binary(subject_id) and Regex.match?(~r/^[0-9a-f]{64}$/, subject_id) do
        case request("ALTER TABLE #{@table} DELETE WHERE subject_id = '#{subject_id}'", "") do
          :ok -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      else
        {:halt, {:error, :invalid_erasure_subject}}
      end
    end)
  end

  defp request(query, body) do
    with {:ok, url} <- clickhouse_url() do
      case Req.post(url,
             params: [query: query],
             body: body,
             headers: [{"content-type", "text/plain"}],
             auth: clickhouse_auth(),
             receive_timeout: 15_000,
             retry: false
           ) do
        {:ok, %{status: status}} when status in 200..299 -> :ok
        {:ok, %{status: status}} -> {:error, {:clickhouse, status}}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp clickhouse_url do
    case System.get_env("CLICKHOUSE_URL") do
      nil -> {:error, :clickhouse_not_configured}
      "" -> {:error, :clickhouse_not_configured}
      url -> {:ok, String.trim_trailing(url, "/")}
    end
  end

  defp clickhouse_auth do
    username = System.get_env("CLICKHOUSE_USER")
    password = System.get_env("CLICKHOUSE_PASSWORD")
    if username && password, do: {:basic, username, password}
  end
end
