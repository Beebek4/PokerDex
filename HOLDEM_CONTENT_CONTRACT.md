# Hold’em Trainer content contract

This document defines the content authors and the application must agree on before building the poker question engine. It keeps the MVP small, reviewable, and reproducible.

## 1. MVP boundaries

- Game: six-handed no-limit Texas Hold’em cash fundamentals.
- Chips are fictional learning units. Show amounts in chips and/or big blinds; never assign cash value.
- A scenario has no ante or straddle unless its structured fields explicitly say otherwise.
- Core tracks cover rules and hand reading, preflop fundamentals, and flop decisions. Tournament strategy is outside the MVP.
- MVP questions are written and reviewed by people. The application may validate cards, hand rankings, and legal actions, but must not invent strategic answer keys at runtime.
- Strategy feedback is a teaching heuristic under stated assumptions, not a solver guarantee or prediction of winnings.

## 2. Required scenario record

Every published scenario needs:

| Field | Required meaning |
| --- | --- |
| `id`, `version`, `status` | Stable scenario identity, immutable published version, and draft/reviewed/published state. |
| `format` | `six_max_cash` for MVP; future formats must be explicit. |
| `table` | Seat count, button seat, and players still in the hand. |
| `hero` | Hero seat/position, starting stack and remaining stack at the decision in big blinds, and two hole cards for Hold’em. Committed chips plus remaining stack must equal the starting stack. |
| `effective_stack_bb` | The largest amount Hero can win from an opponent in this spot; it cannot exceed Hero’s starting stack. |
| `blinds` | Small blind, big blind, and explicit ante/straddle values (zero when absent). |
| `street`, `board` | Current street and zero to five community cards appropriate to that street. |
| `pot` | Current pot before the decision, in the same fictional chip unit as stacks and bets. |
| `action_state` | For `choose_action`: `amount_to_call_bb`, `street_bet_bb`, `hero_street_contribution_bb`, and `contributions_by_seat_bb` (one amount per seat). The call amount and legal actions must agree with this state. |
| `action_history` | Ordered actions since the start of the hand/current street, including actor, action, and amount when applicable. |
| `legal_actions` | Actions the player can take in this exact state for `choose_action`; hand-ranking questions use an empty list. Include amount bounds for bet/raise when a question uses sizing. |
| `question` | Prompt and format, such as `choose_action` or `hand_ranking`; do not hide information needed to decide. |
| `assumptions` | Opponent/range, sizing, or simplification assumptions that materially affect the teaching answer. |
| `skill_tags` | Stable identifiers for the skill(s) being practiced. |
| `answer_key` | Correct mechanical result or authored action rubric, with rationale and reasonable alternatives. |
| `review` | Reviewer approval and review date for the answer key, alternatives, assumptions, and explanation. |

Cards use stable rank/suit identifiers, not display strings. A card cannot appear twice in one deal. MVP bet, pot, and stack amounts are stored in big blinds; the interface may also show fictional chips. The pot is its value before the decision and must equal the sum of all seats’ committed amounts, including folded seats and blinds/antes. The remaining stack is after all prior actions; for Hero, remaining stack plus committed chips must equal the effective stack at the start of the hand. If betting is incomplete, the scenario states whose turn it is and the amount to call. A state that cannot be validated must not be published.

## 3. Question and scoring rules

### Choose an action

- Only show actions legal in the stated state. Do not ask for a bet size in the MVP; sized bets can be added after amount bounds and sizing feedback are designed.
- Each answer choice has a score from 0 to 100, a short label, and an explanation tied to the scenario evidence.
- Default labels: **Strong (100)**, **Reasonable (70)**, **Questionable (30)**, and **Major error (0)**. A question may use fewer score levels when that is clearer.
- Scores grade the decision process under the written assumptions, never whether a later card or showdown happened to reward it.
- If more than one action is defensible, score and explain each defensible action. Do not mark an alternative wrong merely because it is not the reviewer’s first choice.
- A 0 or 30 score needs a specific explanation of the major risk or missed concept. Feedback should give one actionable takeaway.

### Hand ranking

- The app computes hand category, best five cards, kicker comparison, and ties from the cards shown.
- The authored question explains whether it asks for the best hand, winning player(s), or best five-card combination.
- This is objective correctness, kept distinct from the partial strategy score above.

### Content review

Before publication, a poker-knowledgeable reviewer must verify:

1. Card uniqueness, street/card counts, pot and stack arithmetic, action order, and legal actions.
2. The answer key and every scored alternative.
3. The assumptions needed for any strategy judgment and whether the rationale follows from them.
4. Plain-language clarity, one main learning point, and no outcome-based reasoning.
5. No real-money framing, guaranteed-return claims, or pressure to play for money.

Keep the published scenario version and answer key available to attempts already recorded. Editing a question creates a new version; it does not silently change an old attempt’s feedback.

## 4. Learning events and measures

Persist answer selections and rubric scores in the product database. If analytics are enabled, use this small event vocabulary:

| Event | When it fires | Allowed properties |
| --- | --- | --- |
| `lesson_started` | Learner opens or resumes a lesson. | lesson ID, track ID, new/resume |
| `scenario_presented` | A question is shown. | scenario ID/version, skill IDs, question format |
| `answer_submitted` | An answer is saved. | scenario ID/version, score band, attempt number |
| `feedback_viewed` | Feedback is shown after submission. | scenario ID/version, score band |
| `lesson_completed` | The learner reaches the completion state. | lesson ID, track ID, duration bucket |
| `review_started` / `review_completed` | A due review set is opened/completed. | skill IDs, item count |

Do not send hole cards, boards, action histories, answer text, selected-answer text, free-text responses, email, or other direct identifiers to analytics. Any future analytics must be explicitly enabled and configurable; custom learning analytics are not currently enabled in PokerDex.

Report these as learning activity, not a poker ability rating:

- **Lesson completion:** completed lessons / started lessons for the selected period.
- **Question participation:** submitted answers / presented questions.
- **Objective accuracy:** correct hand-ranking answers / submitted hand-ranking answers.
- **Rubric result:** average human-authored score for action decisions, with attempt count and date range.
- **Review completion:** completed due review items / started due review items.

Always show sample size and distinguish objective accuracy from judgment-based rubric results. Do not report win rate, bankroll growth, or a single composite “poker skill” score.

## 5. Generated-puzzle compatibility

The same record shape should support future generated instances without changing the meaning of authored content. A generated instance must additionally preserve its template ID, random seed, generator version, and rules version. Generation may vary only inputs allowed by the reviewed template. Mechanical facts are computed by deterministic rules; strategic scores and explanations come from reviewed template rubrics. If a generated state falls outside those constraints, discard it before showing it to a learner.
