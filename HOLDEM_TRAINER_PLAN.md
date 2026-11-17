# Hold’em Trainer implementation plan

## Product direction to carry forward

Build a responsive Texas Hold’em learning app for beginners and casual players. Keep all chips fictional. Teach decision quality under stated assumptions, not hand outcomes or promises of profit.

**MVP content is hand-authored and reviewed.** Lessons, daily hands, drills, and review puzzles come from a small, versioned content set written by a person and reviewed by someone with sound poker knowledge. No puzzle is generated at answer time in the MVP.

**Later puzzle generation should be deterministic and constrained.** Generate randomized puzzle instances from reviewed templates and validated poker rules. Keep the template, generator version, and generated scenario snapshot so an answer can be explained and reproduced. Do not rely on an LLM to determine the correct answer at runtime.

## What the repository already provides

- Phoenix LiveView app, user accounts, school/course tenancy, course and lesson dashboards.
- A learner path built from `Course` → `Lesson` → ordered `LessonStep` records, with multiple-choice options and per-answer feedback.
- PostgreSQL persistence for `UserSelection` answers and `UserLesson` completions, course progress, and a working local seed path.
- Responsive layouts and an established navigation/component system.

## Initial gaps identified before implementation

- A lesson step currently has plain text and a `:readonly`, `:quiz`, or `:open_ended` kind. It has no structured poker table state, card data, action history, assumptions, or skill tags.
- A step option is binary (`correct?`) with text feedback. The product needs rubric scores and reasonable alternatives such as 100/70/30/0.
- Saved answers track binary `correct` / `total`, not rubric score, content version, or confidence.
- The current learner routes require authentication. The product spec calls for an optional guest start.
- The product needs Home, Learn, Practice, Progress, and Profile destinations; existing routes center around courses and lessons.
- Current seed lessons are generic placeholders. Poker content needs authored scenarios and subject review.
- The repository’s current Elixir/OTP and locked dev tools have a known compile mismatch. The first implementation step must make the normal local command repeatable without leaving temporary dependency edits in the repo.

## Smallest useful MVP interpretation

Follow the spec’s first three complete curriculum tracks: **A: rules and hand reading, B: preflop fundamentals, C: flop decisions**. A track is complete when its included lessons have short explanations, worked examples, runnable practice, answer rationales, and a clear finish state—not just curriculum cards.

For the first question engine support two deterministic formats:

1. **Choose an action:** fold, check, call, bet, or raise when legal in the scenario.
2. **Hand ranking:** identify the winning hand / best five cards using a visible board and hole cards.

The authored content set should include a curated Daily Hand (one to three decisions), short skill drills, and a review set using different scenarios for missed concepts. Defer pot-odds arithmetic, sizing inputs, free-text explanations, complete multi-street hand replay, tournament strategy, streak modes, social features, and runtime generation until the two question formats work well.

## Step-by-step build plan

### Step 0 — Establish a repeatable local baseline

1. Pin a compatible Elixir/Erlang version or update only the incompatible dev-only checkers.
2. Verify the unmodified project commands work: `mix setup`, `mix seed`, `mix phx.server`.
3. Keep local database and demo data separate from any future hosted database. Do not deploy the seeded demo users or their passwords.
4. Record the exact toolchain and startup steps in the README.

**Done when:** a clean local setup can migrate the database, load demo content once, start the app, and serve the learner path without temporary edits to `mix.exs` or config files.

**Progress:** Done. `mix setup` completes on Elixir 1.20.5 / Erlang OTP 29, compiles the app, migrates the development database, and builds assets. Credo was updated within its 1.7 series for this runtime. The app responds locally on port 4000. The seed now creates one local manager, the PokerDex school, and three authored Hold’em tracks. I checked repeated runs against an isolated test database: both snapshots had 1 user, 1 school, 1 school membership, 3 courses, 14 lessons, 73 steps, and 103 options. The temporary database was dropped afterward; local development data was untouched. Generic sample schools and courses are no longer seeded.

### Step 1 — Lock the MVP rules and content contract

1. Confirm the default format is six-handed no-limit cash fundamentals, fictional chips, no ante unless a scenario explicitly includes one, and no tournament advice in the core tracks.
2. Define the scenario context required before an answer: format, players, positions, effective stack, blinds/ante, pot, street, hero cards, board, prior actions, legal actions, and assumptions.
3. Define each action rubric: score, label, rationale, and any assumptions that make it defensible.
4. Set the review bar: a poker-knowledgeable human reviews all answer keys, alternative actions, and explanations before publication.
5. Document the event vocabulary and metric definitions before adding custom analytics. Do not send hole cards, answer text, or free text to analytics.

**Done when:** an author can tell which scenario fields and review checks are required without reading application code.

**Progress:** Done. [HOLDEM_CONTENT_CONTRACT.md](HOLDEM_CONTENT_CONTRACT.md) records the default rules, required scenario fields, rubric and objective-answer distinction, human review checklist, analytics event/property limits, and how generated instances must preserve provenance. The assumptions are now concrete enough to implement Step 2 without choosing a new product direction.

### Step 2 — Add poker scenario data without replacing the course model

1. Keep `Course` and `Lesson` for the curriculum and sequence.
2. Add a poker-specific structured scenario payload to an interactive lesson step (JSONB or an associated `PokerScenario` record). Do not turn the whole app into a generalized content platform.
3. Store card IDs, table/position context, stack/pot values, board, action history, legal actions, game assumptions, and skill tags as structured fields.
4. Add rubric scores and labels to answer choices; retain the existing text feedback for the explanation.
5. Add a persisted numeric score and scenario/content version to each attempt. Keep binary correctness separately for legacy reports and simple accuracy measures; do not overload `correct` to mean partial score.
6. Snapshot the scenario version used by an attempt so later edits do not silently rewrite the learner’s history.
7. Add validation for unique cards, valid card count, legal actions for the state, non-negative/consistent pot and stack values, and complete context.

**Done when:** authored scenarios can be loaded, validated, displayed, answered, and reported without special-case JSON parsing in templates.

**Progress:** Data-layer core implemented. I chose an optional JSONB `poker_scenario` payload on `LessonStep` to reuse the existing course/lesson structure. `StepOption` now has optional rubric `score` and `score_label` fields, and `UserSelection` can store a separate numeric score, scenario version, and full scenario snapshot while retaining the legacy `correct` / `total` values. The lesson-step changeset validates required scenario structure, MVP format/question types, table/blind/stack/pot context, board count, legal-action names, skill tags, and reviewer approval for reviewed/published content. Poker-specific card uniqueness and pot/action mechanics remain Step 3 work. The migration is applied locally. A LiveView test confirms a scored answer saves the version and snapshot; the focused scenario, content, and playback tests pass (138 total). Scenario-screen rendering and score-based feedback remain scheduled for Step 5, with progress reporting in Step 6.

### Step 3 — Build and verify deterministic poker rules

1. Add a small domain module separate from LiveView templates for card parsing, deck uniqueness, best-five-card hand evaluation, ties, and split pots.
2. Add action-state validation so only legal actions appear for the described spot.
3. Validate scenario generation/import data at seed or publish time, not after the learner submits an answer.
4. Create rule tests for card collisions, hand rankings, kickers, ties, illegal actions, and inconsistent pot/stack states.
5. Keep the answer rubric authored. The evaluator validates poker mechanics; it does not claim to be a solver or declare every close strategic spot objectively perfect.

**Done when:** hand-ranking questions are computed consistently, and every authored action question passes scenario validation.

**Progress:** Done. `PokerRules` now parses and normalizes card IDs, rejects duplicate cards, evaluates best-five hands from five to seven cards (including wheel straights, kickers, and ties), ranks players against a shared board, and splits tied pots evenly. It derives the MVP action names from the amount to call and remaining stack, then checks authored action scenarios against their street contributions, listed actions, pot total, and Hero's committed/remaining stack. Scenario validation runs through the lesson-step changeset, so invalid content is rejected when imported or saved rather than after an answer. The focused rules, scenario, content, and playback tests pass (149 total). Strategic scoring remains authored and human-reviewed; this module is not a poker solver.

### Step 4 — Write the first three reviewed curriculum tracks

1. Track A: table flow, betting actions, hand rankings, board reading, and a checkpoint.
2. Track B: position, starting-hand categories, opening decisions, and facing a raise.
3. Track C: made hands/draws/air, board texture, who benefits, and continuation bets.
4. Make each lesson roughly 3–7 minutes, with a plain-language definition, one worked example, and a few questions.
5. Seed content as versioned authored fixtures/files. Keep authoring tools for this MVP limited to the existing dashboard or reviewed seed content; do not build a generalized question-builder first.
6. Have a subject reviewer approve each answer key and record the scenario assumptions. Label the content as learning heuristics where answers depend on ranges or opponent behavior.

**Done when:** all included lessons have runnable questions and reviewed explanations, and each track ends in a checkpoint.

**Progress:** Draft A–C curriculum authored and added to the local idempotent seed: 14 units (including one checkpoint per track), each with a short concept, worked example, at least two playable questions, answer feedback, and a finish step. The 31 question scenarios use stable IDs and version 1, with structured context and authored score rubrics. All scenarios and options pass the content/rules checks, and rerunning `mix seed` adds no duplicate courses, lessons, steps, or options. The answer rubrics remain `draft`; a poker-knowledgeable human must review and approve them before this content is considered ready for public release.

### Step 5 — Build the learner journey and navigation

1. Add a brief onboarding choice for experience level and an optional goal; allow guest start.
2. Map the five destinations to existing LiveViews/components: Home, Learn (curriculum map), Practice, Progress, and Profile/Settings.
3. Make one next action prominent on Home: resume an in-progress lesson, else today’s curated hand, else due review, else the next lesson.
4. Build a poker scenario screen that presents all relevant context before the decision and never reveals future cards early.
5. Show immediate feedback after an answer, including the score label, scenario evidence, main rationale, alternatives, and takeaway.
6. End lessons and sessions with a factual summary and a single next action.

**Done when:** a new learner can start without unnecessary setup, complete a short lesson, understand the feedback, and find the next step.

**Progress:** Implemented the first learner journey. New visitors choose an experience level and optional goal, then start as a guest. Home prioritizes an in-progress lesson, due review, or next lesson; Puzzles, Theory, Progress, and Profile are in the primary navigation. Poker lessons show structured table context and only cards available at that point. Answer feedback separates authored rubric scores from binary hand-ranking accuracy, explains the rationale and alternatives, and lesson completion provides one next action. Step 6 adds saved review and per-skill progress. A curated daily hand remains future work; authored rubrics remain draft until human poker review, and runtime randomized puzzles remain a later phase.

### Step 6 — Save progress and implement learning measures

1. Persist every submitted answer with user/guest ID, scenario ID/version, selected action, score, skill tags, and timestamp.
2. Persist lesson completion and current in-progress state so refresh and return resume safely.
3. Support guest accounts first; offer account creation later to keep progress across devices, and define how guest progress is transferred on registration.
4. Add a review queue for missed concepts using a different authored scenario. Explain why an item is due; do not add spaced scheduling until the due logic and response state are reliable.
5. Show per-skill progress with attempt count and recent accuracy. Label it as practice progress, not a validated poker rating or promise of winnings.
6. Add opt-in reminders only when a real delivery route exists. Otherwise leave reminders out of MVP.

**Done when:** refresh, return, repeat answers, interrupted sessions, and guest-to-account transfer do not lose or duplicate meaningful progress.

**Progress:** Implemented and checked locally. Scenario answers persist the selected option/action (`option_id`), rubric score, scenario ID/version/snapshot (including skill tags), and insertion timestamp. A new acknowledgement marker preserves an answer and its feedback across a refresh until the learner advances; stale submits for an earlier step are ignored. Lesson and review activity are tagged separately, so review attempts contribute to practice history but not lesson completion totals or resume position. Guest account setup retains the same user row, so saved attempts remain attached through email confirmation without a data-copy step. Progress shows total attempts and recent results per skill. A review queue uses each skill’s most recent miss and offers a different authored scenario with a plain-language reason; a successful answer removes that skill from the due queue. Reminder delivery remains out of scope because no real delivery route exists. Content shown in review continues to carry its draft-review notice. The answer-state and review migrations are applied locally. The most recent full test run passed 602 tests.

### Step 7 — Add light motivation only after progress is accurate

1. Add XP for completing learning activities, not for time spent.
2. Consider a gentle daily goal and optional streak only after reviewing the experience with learners.
3. Keep streaks non-punitive; allow rest days and never block content.
4. Defer puzzle streak pressure, hearts, leaderboards, bankroll simulations, cash-value rewards, and urgency notifications.

**Done when:** motivation reinforces learning and can be disabled without losing access or progress.

### Step 8 — Accessibility, privacy, and release validation

1. Verify keyboard and screen-reader operation for cards, positions, actions, tables, feedback, and progress.
2. Pair suit/color cues with labels and symbols; support reduced motion, scalable text, and high contrast.
3. Check common phone and desktop widths; ensure the full scenario context stays readable.
4. Test refresh after an answer, retry after write failure, duplicate submission, guest flow, and lesson completion.
5. Inspect analytics payloads and ensure no free text or private hand data is sent.
6. Review database backups, migrations, production secrets, image storage, email configuration, and hosting cost.
7. Resolve the AGPL-3.0 owner/legal review before choosing a proprietary hosted-product direction.

**Done when:** acceptance criteria in the product specification pass in the running app and the operator can restore persisted data.

## Later phase — Randomized puzzles as learners practice

Introduce generation in a separate milestone after the authored engine and review loop work:

1. Select one validated family first (for example, preflop first-in decisions), with a finite set of authored templates and explicit skill targets.
2. Randomize only constrained inputs such as legal hole cards, positions, stack bands, and prior actions. Reject card collisions and states that do not match the template.
3. Compute facts that have deterministic answers (legal actions, best hand, pot price) with tested domain code. Use human-authored strategy rubrics for judgment-heavy spots.
4. Persist the generated instance, random seed, template ID, rules version, and generator version on the attempt. Replaying the same instance must give the same context and feedback.
5. Add bounds for difficulty and variety; don’t repeat the same template too often and don’t generate a question if the engine cannot explain its answer.
6. Compare generated items to reviewed authored baselines for invalid-state rate, learner confusion, score distribution, and repeat performance.
7. Expand generation to other templates only after review shows the generated scenarios are valid and understandable.

Randomized generation means varied scenarios drawn from vetted rules—not a random action with a post-hoc explanation. Any future AI-assisted authoring should still require validation and human review before it can enter the learner pool.

## Suggested milestones and effort

| Milestone | Main deliverable | Rough effort |
| --- | --- | --- |
| 0. Working baseline | Repeatable local setup and seeded environment | 0.5–1 day |
| 1. Scenario contract and poker rules | Versioned scenario data, validation, hand evaluator | 3–5 days |
| 2. Reviewed A–C content | Complete beginner tracks and authored questions | 4–8 days plus reviewer time |
| 3. Learner loop | Onboarding, Learn/Practice, question feedback, course completion | 4–7 days |
| 4. Persistence and progress | Guest progress, resume, rubric scores, skill summary, review queue | 3–5 days |
| 5. Quality/release prep | Accessibility, privacy, migration/backups, deployment path | 3–5 days |
| Later. Randomized puzzles | One constrained generator family with reproducible attempts | 3–6 days per family |

Estimates assume one developer familiar with Phoenix and timely review from a poker subject-matter expert. Content review and deployment decisions can extend the schedule.
