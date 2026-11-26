// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// Hooks
import ClearFlash from "./hooks/clear_flash";
import LessonSoundEffect from "./hooks/lesson_sound_effect";
import Sortable from "./hooks/sortable";

// Uploaders
import S3 from "./uploaders/s3";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    ClearFlash,
    LessonSoundEffect,
    Sortable,
  },
  uploaders: {
    S3,
  },
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  metadata: {
    keydown: (e, el) => {
      return { key: e.key, metaKey: e.metaKey, ctrlKey: e.ctrlKey };
    },
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#8797AF" }, shadowColor: "rgba(44, 19, 32, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(1000));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Optional, semantic study events only. This deliberately ignores free text,
// pointer coordinates, and events outside controls explicitly marked in HEEx.
const studyEvents = [];
const studyCsrfToken = csrfToken;
let studyFlushTimer;

function flushStudyEvents() {
  if (studyFlushTimer) clearTimeout(studyFlushTimer);
  studyFlushTimer = undefined;
  if (!studyEvents.length) return;

  const events = studyEvents.splice(0, 50);
  fetch("/retention/events", {
    method: "POST",
    credentials: "same-origin",
    headers: {
      "content-type": "application/json",
      "x-csrf-token": studyCsrfToken,
    },
    body: JSON.stringify({ events }),
    keepalive: true,
  }).then((response) => {
    if (response.status === 429 || (response.status >= 500 && response.status !== 503)) retryStudyEvents(events);
  }).catch(() => retryStudyEvents(events));
}

function retryStudyEvents(events) {
  studyEvents.unshift(...events);
  if (studyEvents.length >= 50) flushStudyEvents();
  else if (!studyFlushTimer) studyFlushTimer = setTimeout(flushStudyEvents, 5_000);
}

document.addEventListener("click", (event) => {
  const control = event.target.closest("[data-retention-event]");
  if (!control) return;
  const root = control.closest("[data-retention-opt-in='true']");
  if (!root) return;

  const properties = {};
  for (const [attribute, key] of [
    ["studyScreen", "screen"],
    ["studyControl", "control"],
    ["studyAction", "action"],
    ["studyStreet", "street"],
    ["studyDifficulty", "difficulty"],
    ["studyResult", "result"],
    ["studyOpponentId", "opponent_id"],
  ]) {
    if (control.dataset[attribute]) properties[key] = control.dataset[attribute];
  }

  studyEvents.push({ event_id: crypto.randomUUID(), event_name: control.dataset.retentionEvent, properties });
  if (studyEvents.length >= 50) flushStudyEvents();
  else if (!studyFlushTimer) studyFlushTimer = setTimeout(flushStudyEvents, 5_000);
});

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "hidden") flushStudyEvents();
});
