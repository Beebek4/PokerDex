# PokerDex bot roster

## Status and design intent

These are fictional character directions and the first implemented rule-based tendencies. They are not trained policies or GTO strategies. The initial numeric thresholds are starting values and need review and balancing with a poker-knowledgeable reviewer.

The roster uses familiar tight/loose and passive/aggressive tendencies to make each opponent recognizable and teach one response at a time. Those labels are summaries, not complete strategies; the implementation uses one shared policy with profile parameters. Skill is assigned per character: Teddy, Grandpa, and Mum are Easy; Brother and Sister are Standard; Dad is Hard. Heads-up bot responses pause for 0–3 seconds; tournament responses pause for 0–2 seconds. Style and selected action influence the delay. [PokerStars Learn describes the common playing-style combinations](https://www.pokerstars.com/poker/learn/lesson/other-poker-playing-styles/) and explains that opponents can vary their approach.

## Home route

| Level | Opponent | Character direction | Draft playstyle | Learning purpose |
| --- | --- | --- | --- | --- |
| 0 | Teddy | Gentle warm-up | Check/call only; never raises or folds | Learn street flow, legal actions, and how bets change the pot. Teddy is not a tournament entrant. |
| 1 | Grandpa | Patient | Tight-passive: enters fewer pots, calls more than he raises, and bluffs infrequently | Respect large bets with marginal hands; take small pots when he shows weakness. |
| 2 | Mum | Social | Loose-passive: sees more flops, calls too widely, and rarely raises or bluffs | Value bet good hands more often; avoid low-equity bluffs into a player who dislikes folding. |
| 3 | Brother | Impulsive and unpredictable | Loose-aggressive: enters widely and applies frequent pressure, including selected bluffs | Practise position and composure; don't over-fold, but choose bluff-catchers from the evidence rather than frustration. |
| 4 | Sister | Focused | Tight-aggressive: chooses hands carefully, then uses bets and raises to apply pressure | Think about position and ranges; don't treat every aggressive bet as a bluff. |
| 5 | Dad | Steady and readable | Straightforward and value-heavy; his large bets usually signal strength | Read the action and make disciplined folds with marginal hands. |

Sister and Brother are two distinct takes on the story brief's impulsive sibling rival: Sister is the more focused, selective pressure player, while Brother is the wider, less predictable one. These are draft fictional choices, not claims about your actual family.

### Character and strategy guardrails

- These personality-to-style links are creative choices for the game's fiction, not assumptions about real people based on age or gender. The starter concepts follow the story brief: Grandpa is patient/selective, Mum plays and calls too many hands, Dad's strength is readable, and the sibling rival is impulsive/unpredictable.
- Give each opponent one main, observable tendency. Keep the rest of the decision logic understandable and reasonably sound.
- Make the counter-strategy visible through hand explanations. For example, Mum's calling tendency should reward value bets and make low-equity bluffs less effective.
- Avoid perfect knowledge or reacting to the player's hidden cards. Dad's strategic reads should be transparent and based on public actions, not one result or inaccessible information.
- Keep strategy strength tunable. A profile should teach a recognizable pattern without requiring the learner to guess random actions.
- Use reproducible randomness during development so an unexpected hand can be replayed and debugged.

## House Tournament

The Garage Tournament follows Dad's Home match and includes the family opponents from Grandpa through Dad. Teddy remains a warm-up and is excluded. The current Play flow has a playable multiway tournament with rotating positions and blinds. Treat it as an early implementation: tournament hand progression, short-stack/all-in behavior, side pots, and bot choices need dedicated regression coverage and poker review before a public launch.

## Campaign chip economy

Use fictional chips with no conversion to money, purchases, or redemption. This is especially important for the intended teenage audience. For a recognizable no-limit match structure, use 50-big-blind starting stacks; typical no-limit buy-in ranges commonly sit between 40 and 100 big blinds ([PokerStars buy-in limits](https://www.pokerstars.com/help/articles/ring-game-min-buy-in/96443/)).

| Opponent | Difficulty | Blinds (small/big) | Buy-in | Respect needed |
| --- | --- | ---: | ---: | ---: |
| Teddy | Easy | Free warm-up | 0 | 0 |
| Grandpa | Easy | 1/2 | 100 chips | 1 |
| Mum | Easy | 2/4 | 200 chips | 2 |
| Brother | Standard | 3/6 | 300 chips | 3 |
| Sister | Standard | 4/8 | 400 chips | 4 |
| Dad | Hard | 5/10 | 500 chips | 5 |
| House Tournament | — | Event | 2,500 chips | 6 |

- Seed the campaign with **1,000 chips and 0 Respect**. The first win against each opponent awards one Respect and unlocks the next level. Respect never drops, and replay wins do not farm more unlock points.
- Match the opponent's stack to the player's buy-in. Reserve the player's entry before the match. On a full match win, return both entries to the player's bankroll, so the net reward is the opponent's buy-in. On a loss, the player's entry is spent; unlocked opponents can be replayed to build the bankroll again.
- A clean sweep earns 1,500 chips from the opponents, taking the starting 1,000 to **2,500 chips**. The House Tournament requires **2,500 chips and 6 Respect**, and uses the player's entire available bankroll as its entry.
- If the chip balance falls below 100, a Teddy warm-up win restores it to 100. This no-purchase recovery path prevents a losing streak from permanently blocking another match.
- Persist the campaign bankroll and Respect/unlocked level so leaving Play or refreshing does not erase progress. Store current hand state separately; the existing Rust hand session cannot currently be resumed after a refresh.

The Play selection screen reads its opponent list from `Zoonk.Poker.Opponents`. A campaign starts with 1,000 fictional chips and 0 Respect. Match entry is reserved when play starts; a win returns both entries and adds one Respect, while a loss spends the player's entry. Completed results drive Progress. Returning to the map abandons an unfinished match and refunds its entry. After refresh, the app reports that the hand cannot resume and asks the player to refund the entry; merely opening another tab no longer abandons it automatically.

## Implementation order

1. Keep Teddy as the Level 0 check/call tutorial opponent.
2. Validate each baseline profile's decisions and difficulty balance against reviewed hand examples. Current thresholds are explanatory heuristics and do not calculate full equity or ranges.
3. Keep the action-by-action engine interface as the only route for player and bot actions. The HUD records the actual actor/action sequence.
4. Add hand-level history only when it supports a defined learning or debugging need; do not expose private cards to bot observations.
5. Add focused regression coverage and poker review for dealer rotation, all-in/side-pot rules, and tournament bot behavior; improve those rules based on findings.
