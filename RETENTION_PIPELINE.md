# Retention and playstyle data

## Data flow

```text
Poker LiveView ── completed match ──> Postgres transaction
                                      ├─ poker_matches (existing campaign record)
                                      ├─ poker_match_stats (one compact summary per match)
                                      ├─ poker_player_stats / poker_opponent_stats (small lifetime rollups)
                                      └─ retention_outbox_events (only when the user opts in)
                                                │
                                                └─ Oban publisher ──> Kafka
                                                                       │
                                                           Broadway analytics worker
                                                                       │ batches
                                                                       ▼
                                                                 ClickHouse
                                                                       │
                                                            Prometheus / Grafana
```

Match actions are counted in the LiveView process while a match is active. They are written together only when the match completes. The Progress chart and opponent reads use Postgres rollups, whose row count is bounded to one player row per mode and one row per opponent per mode. No action-by-action poker hand history is stored.

The optional product study stream is separate. Its profile setting defaults to off. Only opted-in accounts send explicitly marked semantic actions, and collection stays disabled until Kafka is configured so events cannot pile up in Postgres while the analytics pipeline is offline. The API accepts a maximum of 50 events per request and only fixed event/property values; it drops unknown fields. It does not accept free text, cursor positions, or raw browsing history. Match outcome events are generated server-side and enter the same outbox transaction as the completed match and stat rollups when Kafka is configured. Turning consent off queues a pseudonymous erasure marker; deleting an opted-in account does the same. ClickHouse removes that pseudonym's detailed events. The long-lived daily cohort table contains no user key and cannot be linked back to one account.

The outbox publisher claims rows with a short PostgreSQL lease, writes keyed events to Kafka, and marks them published after broker acknowledgement. A crash between Kafka acknowledgement and the Postgres update can produce a duplicate, so consumers must be idempotent. ClickHouse keeps event detail for 30 days and stores user-free daily cohort aggregates for 365 days. Failed downstream events go to the Kafka dead-letter topic for review/replay.

PromEx exposes low-cardinality Phoenix, Ecto, Oban, BEAM, and Broadway metrics. User IDs, session IDs, opponents, and event properties are not metric labels.

## Start the optional local stack

1. Start Docker Desktop.
2. From the project root, start Kafka, ClickHouse, Prometheus, and Grafana:

   ```sh
   docker compose -f docker-compose.retention.yml up -d
   ```

3. In a terminal, set the local-only connection values and run the web app:

   ```sh
   set -a
   source .env.retention.example
   set +a
   mix ecto.migrate
   mix phx.server
   ```

4. In a second terminal, load the same values and run the separate analytics consumer:

   ```sh
   set -a
   source .env.retention.example
   set +a
   RETENTION_ROLE=analytics mix run --no-halt
   ```

5. Open PokerDex at `http://localhost:4000`, Prometheus at `http://localhost:9090`, and Grafana at `http://localhost:3000` (`admin` / `admin`). Prometheus scrapes the web process on port 4021 and the analytics worker on 4022. Kafka UI is not included; Kafka topics can be inspected with `docker compose -f docker-compose.retention.yml exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list`.

The profile checkbox is under **Settings → Profile**. With it off, the study endpoint rejects events and no client interaction stream is written. With the optional services stopped, the page also stops emitting study actions. Match rollups remain enabled because they power the user's own Progress page.

The web process can run without Kafka or ClickHouse. In that case the Broadway consumer does not start, and consented events remain in Postgres until a configured Kafka publisher is available. Do not enable opt-in studies in a hosted environment until Kafka, ClickHouse, retention TTLs, access controls, and the Prometheus token have been configured there.

## Scale checks

`priv/retention/load/k6.js` describes the planned 1,000 event/second, 10-minute ingestion exercise. It requires a valid signed-in session cookie and CSRF token for an opted-in test account. Run it only against a disposable local or staging database; the test writes 600,000 events by design.

```sh
k6 run -e BASE_URL=http://localhost:4000 -e SESSION_COOKIE='...' -e CSRF_TOKEN='...' priv/retention/load/k6.js
```

At-least-once delivery is intentional. Event IDs are stable from the outbox through Kafka and ClickHouse, and daily cohort aggregates use unique event IDs. Validate ClickHouse insert deduplication under the deployed version before using the stream for experiments.
