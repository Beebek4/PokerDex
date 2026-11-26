CREATE DATABASE IF NOT EXISTS pokerdex;

CREATE TABLE IF NOT EXISTS pokerdex.retention_events
(
    event_id UUID,
    subject_id FixedString(64),
    event_name LowCardinality(String),
    schema_version UInt16,
    properties String,
    occurred_at DateTime64(3, 'UTC')
)
ENGINE = ReplacingMergeTree
PARTITION BY toYYYYMM(occurred_at)
ORDER BY (event_name, occurred_at, event_id)
TTL occurred_at + INTERVAL 30 DAY DELETE;

CREATE TABLE IF NOT EXISTS pokerdex.retention_daily_cohorts
(
    event_date Date,
    event_name LowCardinality(String),
    screen LowCardinality(String),
    control LowCardinality(String),
    unique_events AggregateFunction(uniq, UUID)
)
ENGINE = AggregatingMergeTree
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, event_name, screen, control)
TTL event_date + INTERVAL 365 DAY DELETE;

CREATE MATERIALIZED VIEW IF NOT EXISTS pokerdex.retention_daily_cohorts_mv
TO pokerdex.retention_daily_cohorts
AS SELECT
    toDate(occurred_at) AS event_date,
    event_name,
    JSONExtractString(properties, 'screen') AS screen,
    JSONExtractString(properties, 'control') AS control,
    uniqState(event_id) AS unique_events
FROM pokerdex.retention_events
GROUP BY event_date, event_name, screen, control;
