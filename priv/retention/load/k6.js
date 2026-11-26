import http from "k6/http";
import { check } from "k6";

const eventsPerRequest = 50;

export const options = {
  scenarios: {
    retention_ingest: {
      executor: "constant-arrival-rate",
      rate: 20,
      timeUnit: "1s",
      duration: "10m",
      preAllocatedVUs: 10,
      maxVUs: 40,
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<500"],
  },
};

const batch = Array.from({ length: eventsPerRequest }, () => ({
  event_name: "puzzle.answered",
  properties: {
    screen: "practice",
    control: "answer",
    street: "flop",
    difficulty: "medium",
    result: "correct",
  },
}));

export default function () {
  const response = http.post(
    `${__ENV.BASE_URL}/retention/events`,
    JSON.stringify({ events: batch }),
    {
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": __ENV.CSRF_TOKEN,
        Cookie: __ENV.SESSION_COOKIE,
      },
    },
  );

  check(response, {
    "event batch accepted": (res) => res.status === 200,
  });
}
