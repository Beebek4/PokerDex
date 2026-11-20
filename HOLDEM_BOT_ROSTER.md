# PokerDex bot roster

## Status and design intent

These are draft character directions and poker tendencies, not implemented strategies. The personality descriptions are fictional starting points because the real family members' personalities have not been described yet. Replace them with your intended character traits whenever you like.

The roster uses familiar tight/loose and passive/aggressive tendencies to make each opponent recognizable and teach one response at a time. Those labels are summaries, not complete strategies; players can combine traits or change gears. [PokerStars Learn describes the common playing-style combinations](https://www.pokerstars.com/poker/learn/lesson/other-poker-playing-styles/) and explains that opponents can vary their approach.

## Home route

| Level | Opponent | Character direction | Draft playstyle | Learning purpose |
| --- | --- | --- | --- | --- |
| 0 | Teddy | Gentle warm-up | Check/call only; never raises or folds | Learn street flow, legal actions, and how bets change the pot. Teddy is not a tournament entrant. |
| 1 | Grandpa | Patient | Tight-passive: enters fewer pots, calls more than he raises, and bluffs infrequently | Respect large bets with marginal hands; take small pots when he shows weakness. |
| 2 | Mum | Social | Loose-passive: sees more flops, calls too widely, and rarely raises or bluffs | Value bet good hands more often; avoid low-equity bluffs into a player who dislikes folding. |
| 3 | Sister | Focused | Tight-aggressive: chooses hands carefully, then uses bets and raises to apply pressure | Think about position and ranges; don't treat every aggressive bet as a bluff. |
| 4 | Brother | Impulsive and unpredictable | Loose-aggressive: enters widely and applies frequent pressure, including selected bluffs | Practise position and composure; don't over-fold, but choose bluff-catchers from the evidence rather than frustration. |
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

Draft assumption: the House Tournament follows Dad's Home match and includes the family opponents from Grandpa through Dad. Teddy remains a warm-up and is excluded. The event should introduce multiway decisions, changing blinds, and elimination pressure as a separate format from the Home heads-up matches.

The current native engine only supports heads-up prototype play. The tournament needs multi-player hand state, position rotation, legal short-stack/all-in behavior, side pots, and a defined blind/elimination structure before it can be playable. Tournament bot policies should be a later layer over those rules, not special cases in the Play screen.

## Campaign chip economy

Use a fictional chip currency with no conversion to money, purchases, or cash-out. This is especially important for the intended teenage audience. For a recognizable no-limit cash-game structure, use 50-big-blind starting stacks; cash-game buy-in ranges commonly sit between 40 and 100 big blinds ([PokerStars buy-in limits](https://www.pokerstars.com/help/articles/ring-game-min-buy-in/96443/)).

| Opponent | Blinds (small/big) | Buy-in | Respect needed |
| --- | ---: | ---: | ---: |
| Teddy | Free warm-up | 0 | 0 |
| Grandpa | 1/2 | 100 chips | 1 |
| Mum | 2/4 | 200 chips | 2 |
| Sister | 3/6 | 300 chips | 3 |
| Brother | 4/8 | 400 chips | 4 |
| Dad | 5/10 | 500 chips | 5 |
| House Tournament | Event | 2,500 chips | 6 |

- Seed the campaign with **1,000 chips and 0 Respect**. Beat Teddy to earn 1 Respect; each subsequent cash-game win awards another Respect point and unlocks the next opponent. Respect never drops on a later loss.
- Match the opponent's stack to the player's buy-in. Reserve the player's entry before the match. On a full match win, return both entries to the player's bankroll, so the net reward is the opponent's buy-in. On a loss, the player's entry is spent; unlocked opponents can be replayed to build the bankroll again.
- A clean sweep earns 1,500 chips from the opponents, taking the starting 1,000 to **2,500 chips**. The House Tournament requires **2,500 chips and 6 Respect**, and uses the player's entire available bankroll as its entry.
- Add a no-purchase recovery path before launch (for example, earn play chips from puzzles or a free practice reward) so a losing streak cannot permanently block a player from the next buy-in.
- Persist the campaign bankroll and Respect/unlocked level so leaving Play or refreshing does not erase progress. Store current hand state separately; the existing Rust hand session cannot currently be resumed after a refresh.

The Play selection screen currently displays the proposed starting balance, Respect, buy-ins, blinds, and tournament requirements. These are presentation values only until cash awards, Respect unlocks, persistence, and playable opponents are implemented.

The current Play code does not yet implement a cross-match bankroll, buy-ins, or level unlocking. `PokerHealth` only moves chips within the current heads-up match. Add the campaign economy when implementing the first playable Home rival, and keep Teddy's free practice separate.

## Implementation order

1. Keep Teddy as the Level 0 check/call tutorial opponent.
2. Add one deterministic profile at a time, starting with Grandpa or Mum, and confirm its defining tendency is visible over a sample of hands.
3. Record actual bot actions in hand history so the HUD and post-hand explanation match what the bot did.
4. Make Dad's predictable strength signals consistent, then add any cross-hand adaptation only after observations can be stored and replayed reliably.
5. Build tournament rules and multiway engine support before implementing the House Tournament opponents.
