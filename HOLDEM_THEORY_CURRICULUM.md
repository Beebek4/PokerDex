# Hold’em Trainer: Poker Theory Curriculum
## Topic map, lesson plan, and practice ideas

This document turns the initial topic list—betting ranges, bet sizing, board textures, and position—into a sequenced curriculum. It is designed for a beginner-to-intermediate Texas Hold’em learning app, with advanced topics clearly separated for later.

**Recommended core game context:** No-limit Texas Hold’em, six-handed cash-game examples, fictional chips. Add a distinct tournament track later because stack, payout, and blind-level decisions introduce additional concepts.

**Teaching principle:** Teach one idea, show it in a hand, then ask the learner to make a decision and explain the evidence. A lesson should not imply that a poker heuristic is a universal rule. Strategy varies with positions, ranges, stack depth, bet sizes, opponent tendencies, and game format.

---

## 1. Curriculum map at a glance

| Order | Module | Main question the learner can answer |
|---|---|---|
| 0 | Poker foundations | What is happening in the hand, and what are my legal actions? |
| 1 | How to think about decisions | What information matters, and how do I compare choices? |
| 2 | Position and preflop ranges | Which hands should I enter with from this seat and action sequence? |
| 3 | Hand strength, draws, and equity | How strong is my hand now, and how often can it improve or win? |
| 4 | Board texture and range interaction | Which parts of each player’s range connect with this board? |
| 5 | Betting purpose and bet sizing | Why am I betting, and how large should the bet be? |
| 6 | Responding to bets | When should I fold, call, raise, or bluff-catch? |
| 7 | Turn and river planning | How does the hand change as new cards and actions arrive? |
| 8 | Hand reading and blockers | What hands can the opponent reasonably have now? |
| 9 | Opponent tendencies and exploitative play | How should I adjust to a specific observed tendency? |
| 10 | Stack depth and pot geometry | How do stacks and the pot shape future decisions? |
| 11 | Integrated hand analysis | How do I combine all the concepts in a complete hand? |
| 12 | Advanced strategy concepts | What are ranges, frequencies, and balanced strategies doing under the hood? |
| 13 | Decision discipline and review | How do I learn from a hand without being misled by its result? |

### Where the user’s current ideas fit

- **Position** becomes Module 2 and then appears as a factor throughout later modules.
- **Betting ranges** should be split into two concepts: *which hands are in a player’s range* (Modules 2 and 8) and *which hands bet/check/raise at a decision point* (Modules 5 and 12).
- **Board textures** becomes Module 4.
- **Sizing bets** becomes Module 5, after learners understand the purpose of a bet and the ranges involved.

---

## 2. Lesson format to use in every module

Each lesson should take about 3–7 minutes and follow this pattern:

1. **Learning objective:** One clear action the learner will be able to perform.
2. **Plain-language idea:** Explain the concept with minimal jargon.
3. **Visual model:** Table view, range grid, pot diagram, or board example.
4. **Worked hand:** Show the reasoning step by step.
5. **Decision puzzle:** Ask the learner to choose an action or identify a concept.
6. **Feedback:** Explain why, name the assumptions, and acknowledge reasonable alternatives.
7. **Takeaway:** A concise memory aid, labeled as a heuristic when it is not universal.
8. **Review prompt:** Add a missed or uncertain concept to a later review session.

### Recommended lesson interaction types

- Choose fold, check, call, bet, raise, or all-in when legal.
- Pick a bet purpose: value, bluff, semi-bluff, protection, or pot control.
- Select hands that belong in a likely range.
- Mark cards or hand categories that improve the board.
- Compare two bet sizes and explain the trade-off.
- Calculate or estimate pot odds and outs.
- Replay a hand street by street without showing future cards early.
- Sort decisions into “strong,” “reasonable,” or “review,” rather than forcing false precision.

---

## 3. Detailed modules and lesson ideas

## Module 0 — Poker foundations

**Purpose:** Make sure learners understand the rules and the hand state before asking them to study strategy.

### Lesson 0.1: The shape of a Hold’em hand
- Hole cards, community cards, dealer button, blinds.
- Preflop, flop, turn, river, showdown.
- How the dealer button moves and how blinds rotate.

### Lesson 0.2: Actions and betting order
- Check, bet, call, raise, fold, all-in.
- Who acts first and last on each street.
- What happens when everyone checks, everyone folds, or a player is all-in.

### Lesson 0.3: Hand rankings and best five cards
- High card through royal flush.
- Best five-card hand from the available seven cards.
- Kickers, ties, split pots, and board-playing hands.

### Lesson 0.4: Pot and stack basics
- Pot size, effective stack, bet amount, and amount to call.
- Side-pot concept as an optional lesson after the basics.

**Practice:** Rank hands, identify legal actions, trace action order, and calculate a simple pot after bets.

---

## Module 1 — How to think about a poker decision

**Purpose:** Introduce a repeatable reasoning process before teaching detailed strategies.

### Lesson 1.1: A hand is a decision sequence
- Make one decision using only the information available at that time.
- Do not use the river card to judge a flop decision.
- Separate the choice from the eventual result.

### Lesson 1.2: Ask the five context questions
- What is my position?
- What actions happened before me?
- What are the pot and effective stack?
- What range of hands could each player have?
- What is my goal if I bet, call, check, raise, or fold?

### Lesson 1.3: Options have trade-offs
- Folding gives up the pot but avoids further cost.
- Calling continues while keeping weaker hands in the opponent’s range.
- Raising can get value, deny equity, or create folds, but risks more chips.
- Checking can control the pot or induce action, but may give a free card.

### Lesson 1.4: Outcome is not the same as decision quality
- Good decisions sometimes lose.
- Poor decisions sometimes win.
- Review the information and assumptions available when the choice was made.

**Practice:** After a simulated hand, ask “Would this still be a sound decision if the next card were different?”

---

## Module 2 — Position and preflop ranges

**Purpose:** Teach what hands to enter with and how the answer changes by seat and action.

### Lesson 2.1: Position at the table
- Early, middle, late position, button, small blind, big blind.
- Acting later provides information and lets a player close the action.
- Position affects hand selection and later-street choices.

### Lesson 2.2: Hand categories and starting-hand strength
- High pairs, medium pairs, strong high-card hands, suited connectors, weak offsuit hands.
- Raw hand strength vs. playability after the flop.
- Why a hand’s value depends on position, stack depth, and number of opponents.

### Lesson 2.3: Opening ranges by position
- What an opening range is: hands a player chooses to raise first into the pot.
- Why early-position ranges are generally tighter and late-position ranges wider.
- Use a simple visual chart as a starting point, not a universal command.
- Explain how table size changes the positions and range assumptions.

### Lesson 2.4: Facing an open raise
- Fold, call, or three-bet.
- Cold-calling vs. calling from the big blind.
- Position, opener position, raise size, and players behind.

### Lesson 2.5: Three-betting
- A three-bet is the first re-raise before the flop.
- Value three-bets vs. bluff/semi-bluff three-bets.
- How position and original raiser’s range matter.
- Avoid a single fixed three-bet range for every position.

### Lesson 2.6: Defending the blinds
- The forced blind contribution and pot odds.
- Why a price can encourage a wider defense, while being out of position remains costly.
- When to call, three-bet, or fold from the big blind.

### Lesson 2.7: Limping, isolating, and multiway pots
- What limping means and why it can create multiway pots.
- Raising to isolate a weaker or passive player.
- Why hands change value when several players see a flop.

**Practice:** Preflop puzzle sets grouped by seat: first in, facing raise, in the small blind, in the big blind, and facing a three-bet.

---

## Module 3 — Hand strength, draws, and equity

**Purpose:** Move from “what cards do I have?” to “how does my hand perform against possible hands?”

### Lesson 3.1: Made hands and hand classes
- Top pair, middle pair, bottom pair, overpair, two pair, set, straight, flush.
- Relative hand strength: a pair can be strong on one board and vulnerable on another.

### Lesson 3.2: Draws and outs
- Flush draws, open-ended straight draws, gutshots, overcards, backdoor draws.
- Count cards that can improve the hand.
- Distinguish clean outs from cards that may also improve an opponent.

### Lesson 3.3: Equity intuition
- Equity as an estimated share of the pot if remaining cards are dealt against a specified hand or range.
- Equity changes by street and by opponent range.
- Equity is not the same thing as a guarantee of winning or a profitable call.

### Lesson 3.4: Pot odds
- Compare the cost of calling with the final pot available.
- Show a chip diagram before teaching a formula.
- Convert a simple price into a required equity threshold.

### Lesson 3.5: Implied and reverse implied odds
- Implied odds: future chips that may be won when a draw hits.
- Reverse implied odds: future chips that may be lost even when a hand improves.
- Stack depth, opponent tendencies, and position affect these estimates.

### Lesson 3.6: Equity realization
- A hand’s raw equity may not all reach showdown.
- Position, aggression, and future decision difficulty affect how much equity is realized.
- Keep this intuitive at first; avoid presenting a fake exact number without a model.

**Practice:** Count outs, call/fold using pot odds, compare equity against different ranges, and identify dirty outs.

---

## Module 4 — Board texture and range interaction

**Purpose:** Make “reading the board” a structured skill rather than a list of labels.

### Lesson 4.1: Board texture basics
- Paired vs. unpaired boards.
- Rainbow vs. two-tone vs. monotone boards.
- Dry vs. connected/wet boards.
- High-card vs. low-card boards.

### Lesson 4.2: What changed on this board?
- Identify made hands, draws, and possible combinations.
- Recognize which turn cards complete or strengthen draws.
- Notice when a board changes from static to dynamic.

### Lesson 4.3: How the board interacts with ranges
- Which player has more strong hands on a given board?
- Introduce range advantage in plain language.
- Avoid assuming the preflop raiser always has the advantage.

### Lesson 4.4: Nut advantage
- What the strongest possible hands are for each player’s range.
- Why some boards support larger bets because one range contains more very strong hands.
- Use a visual “top of range” comparison.

### Lesson 4.5: Static and dynamic boards
- Static boards are less likely to change the best hand dramatically.
- Dynamic boards have more turn/river cards that alter hand strength.
- How this affects betting urgency and protection.

**Practice:** Label board features, select likely draws, and compare which range connects better before choosing an action.

---

## Module 5 — Betting purpose and bet sizing

**Purpose:** Clarify why a player bets before asking how much to bet.

### Lesson 5.1: The three main reasons to bet
- **Value:** Worse hands may call.
- **Bluff:** Better hands may fold.
- **Semi-bluff:** A draw can improve when called, and some better hands may fold now.
- Protection can be taught as a supporting purpose: charge hands with meaningful equity.

### Lesson 5.2: Value betting
- Identify worse hands that can continue.
- Thin value vs. strong value.
- Why a bet is not automatically for value just because the player has a pair.

### Lesson 5.3: Bluffing conditions
- Fold equity: how often the opponent may fold.
- Which better hands can fold?
- Which worse hands call?
- Why bluffing into a player who rarely folds is usually less attractive.

### Lesson 5.4: Semi-bluffs and draw aggression
- Combine current fold equity with potential to improve.
- Choose draws with useful outs and future playability.
- Contrast betting a draw with passively calling.

### Lesson 5.5: Bet size vocabulary
- Small, medium, large, and overbet as pot-relative concepts.
- Convert a bet into a percentage of the pot.
- A size is meaningful only with context: board, ranges, position, stacks, and goal.

### Lesson 5.6: Choosing a size for value
- Which worse hands can call each size?
- How does a larger size change the opponent’s continuing range?
- How should the size relate to future streets and remaining stack?

### Lesson 5.7: Choosing a size for a bluff
- Risk vs. reward and fold equity.
- Why a larger bluff needs to work more often.
- How board/range advantage and opponent tendencies affect the size.

### Lesson 5.8: Continuation betting
- What a continuation bet is: the preflop raiser bets on the flop.
- Why the preflop raiser may have range or nut advantage on some boards.
- When to check, including boards that connect well with the caller’s range.
- Avoid “always c-bet because you raised preflop.”

### Lesson 5.9: Check-raising and donk betting (later beginner/intermediate)
- Check-raise as a value/bluff line after checking to an aggressor.
- Donk bet as a lead into the preflop aggressor.
- Why action sequence and board interaction matter.

**Practice:** Pick a bet purpose, then choose a size band. Give feedback on both separately.

---

## Module 6 — Responding to bets

**Purpose:** Teach decisions after an opponent bets or raises.

### Lesson 6.1: Fold, call, raise framework
- Fold when continuing is not justified under the situation.
- Call to keep bluffs and weaker hands in, or realize equity.
- Raise for value, as a bluff, or as a semi-bluff.

### Lesson 6.2: Facing a continuation bet
- Consider board texture, position, range interaction, and bet size.
- Continue with value hands, draws, and selected bluffs.
- Avoid defending every hand merely because the bet is small.

### Lesson 6.3: Bluff-catching
- A bluff-catcher beats the opponent’s bluffs but loses to value bets.
- Estimate whether the opponent has enough bluffs in their range.
- Use action history and tendencies, not the eventual revealed cards.

### Lesson 6.4: Facing raises
- What a raise says about ranges, not a single exact hand.
- Raise size, prior action, player type, and stack depth.
- Avoid automatically treating every raise as a monster or a bluff.

### Lesson 6.5: Minimum defense frequency (advanced optional)
- Introduce the idea that folding too often can make a range exploitable.
- Teach the concept visually with a simplified bet-size example.
- Clearly state that MDF is not a command to call with weak hands regardless of range or opponent.

**Practice:** Response puzzles with different opponent styles and bet sizes.

---

## Module 7 — Turn and river planning

**Purpose:** Encourage learners to make a plan that can adapt as the hand develops.

### Lesson 7.1: Plan before betting the flop
- Which turn cards help your range, hurt your range, or change nothing?
- What will you do if called or raised?
- How much of the effective stack remains?

### Lesson 7.2: Turn barrels
- Continue betting for value, pressure, or equity denial.
- Selectively double-barrel based on turn card and opponent range.
- Recognize cards that are poor bluff cards.

### Lesson 7.3: River value bets
- What worse hands can call?
- When is a small “thin value” bet preferable to checking?
- Why showdown value can make checking better.

### Lesson 7.4: River bluffs
- Tell a coherent story based on previous actions.
- Identify which better hands can fold.
- Choose bluffs with useful blockers or low showdown value where appropriate.

### Lesson 7.5: Facing a river bet
- Pot odds and required bluff frequency.
- Bluff-catchers, value-heavy lines, and opponent tendencies.
- Do not call only because the player is curious or has already invested chips.

### Lesson 7.6: Check-raise and overbet rivers (advanced)
- Polarized ranges: very strong hands and bluffs.
- When large bets put pressure on capped ranges.
- Make advanced examples explicitly assumption-dependent.

**Practice:** Street-by-street replay. Ask for a plan, then reveal the next card only after the learner commits.

---

## Module 8 — Hand reading, ranges, and blockers

**Purpose:** Help learners reason about groups of possible hands rather than guessing one exact holding.

### Lesson 8.1: What is a range?
- A range is a set or distribution of hands a player may have.
- Start with broad categories, then use a hand grid in advanced practice.
- Ranges change with position and actions.

### Lesson 8.2: Narrowing a range by action
- Preflop opening, calling, and three-betting ranges.
- How flop checks/bets/raises change plausible holdings.
- What a player’s action does not prove.

### Lesson 8.3: Combos and card removal
- Count combinations of pairs and suited/offsuit hands.
- Board and hole cards remove possible combinations.
- Use simple visual blockers before teaching full combo math.

### Lesson 8.4: Blockers
- A blocker is a known card that reduces available combinations.
- How blockers can affect calling, bluffing, and value hands.
- Avoid treating one blocker as a reason to bluff by itself.

### Lesson 8.5: Range advantage and capped ranges
- Range advantage: one player’s range has more overall equity in a spot.
- Capped range: a range may contain fewer of the strongest hands after an action.
- Connect these ideas back to board texture and betting.

**Practice:** Select plausible opponent hands after each action and explain which hands were removed or discounted.

---

## Module 9 — Opponent tendencies and exploitative play

**Purpose:** Teach evidence-based adjustments to the app’s bot styles and later to human opponents.

### Lesson 9.1: Tight/loose and passive/aggressive
- Explain each axis independently.
- TAG, LAG, nit, loose-passive fish, and maniac as broad shorthand.
- Make clear that a style label is a tendency, not certainty.

### Lesson 9.2: Observe before labeling
- What counts as evidence over a sample of hands?
- Distinguish observed statistics from designed bot profile settings.
- Small samples are noisy; show the hand count with observed tendencies.

### Lesson 9.3: Adjusting to a player who calls too much
- Bluff less often with weak hands.
- Value bet more hands and choose sizes that worse hands can call.
- Avoid assuming the player will never fold.

### Lesson 9.4: Adjusting to a player who folds too much
- Steal and bluff more selectively in suitable spots.
- Keep value ranges strong when called.
- Avoid turning every hand into a bluff.

### Lesson 9.5: Adjusting to aggression
- Let aggressive opponents bluff when appropriate.
- Identify which hands can call down or re-raise for value.
- Do not fight aggression just to prove a point.

### Lesson 9.6: Baseline strategy vs. exploit
- Baseline: a robust default when little is known.
- Exploit: a deviation based on a reliable tendency.
- Explain that exploitative adjustments can be counter-exploited if the read is wrong.

**Practice:** Play against the app’s bots with profiles visible, then hidden, and compare the learner’s read with the bot’s actual tendency.

---

## Module 10 — Stack depth and pot geometry

**Purpose:** Connect chip stacks and pot sizes to how many decisions remain.

### Lesson 10.1: Effective stack
- The smaller relevant stack limits how many chips can be won or lost between players.
- Use fictional-chip examples and clear table visuals.

### Lesson 10.2: Stack-to-pot ratio (SPR)
- Compare effective stack with pot at the start of a postflop street.
- Lower SPR means fewer chips remain relative to the pot; higher SPR leaves more room for future betting.
- Use as a planning aid, not an automatic all-in rule.

### Lesson 10.3: Building the pot across streets
- How flop sizing affects turn and river bets.
- Plan a sequence of bets around the remaining stack.
- Avoid accidentally committing a large stack with a marginal hand.

### Lesson 10.4: Multiway pots
- More opponents mean a stronger average continuing range.
- Bluffing generally becomes harder with multiple callers.
- Hand equity and draw quality change with more players.

**Practice:** Given stack/pot combinations, choose a sensible plan and see how different flop sizes affect later streets.

---

## Module 11 — Integrated hand analysis

**Purpose:** Combine the concepts into useful full-hand practice.

### Lesson 11.1: Preflop to flop
- Position and opening ranges.
- Who has the range/nut advantage on the flop?
- Continue bet, check, or respond to a bet.

### Lesson 11.2: Draw and pot-odds hand
- Count outs and estimate equity.
- Compare call price with pot odds.
- Consider implied/reverse implied odds and position.

### Lesson 11.3: Value-bet hand
- Identify worse hands that continue.
- Choose a size based on target range and future stack.
- Review result separately from decision quality.

### Lesson 11.4: Bluff and bluff-catch hand
- Build a plausible range story across streets.
- Decide which hands bluff and which bluff-catch.
- Include opponent tendency information and confidence.

### Lesson 11.5: Review an entire hand
- Replay each decision in order.
- Show only the cards known at each decision.
- Compare baseline and exploitative options.
- End with one or two learning takeaways, not a wall of analysis.

---

## Module 12 — Advanced strategy concepts

This module is optional and should unlock after the learner completes the core track.

### Lesson 12.1: Range construction
- Value hands, bluffs, draws, and checks within a betting range.
- Why betting only strong hands is predictable.

### Lesson 12.2: Polarized and merged ranges
- Polarized ranges contain very strong hands and bluffs.
- Merged ranges include a wider band of hands betting for thinner value/protection.
- Link to sizing and opponent response.

### Lesson 12.3: Mixed strategies and frequencies
- A strategy can choose multiple actions with different frequencies.
- Frequencies are attached to exact game assumptions and a reference model.
- A frequency is not a probability that the action will win.

### Lesson 12.4: Expected value and indifference
- EV compares expected outcomes under a defined model.
- Similar-EV actions may both be reasonable.
- A heuristic lesson must not be presented as solver output.

### Lesson 12.5: Minimum defense and bluffing thresholds
- Relate bet size to how often a bluff needs to work.
- Explain limitations of simplified formulas in multi-street and multiway spots.

### Lesson 12.6: Range vs. range thinking
- Compare distributions rather than one hand against one hand.
- Introduce aggregate equity, nut advantage, and range interaction.
- Hide advanced grids until the learner requests more detail.

---

## Module 13 — Decision discipline and review

This is a supporting skill throughout the curriculum, not a substitute for strategy lessons.

### Lesson 13.1: Variance and short-term results
- Results vary even when decisions are consistent.
- A short winning or losing session does not establish skill level.

### Lesson 13.2: Review without hindsight
- Pause at the decision point and hide future cards.
- Record the learner’s reasoning before revealing the outcome.
- Separate what was known, inferred, and revealed later.

### Lesson 13.3: Find one recurring leak
- Group missed questions by concept.
- Choose a focused practice set instead of repeating the whole course.

### Lesson 13.4: Session reflection
- What decision felt uncertain?
- Which information did you use?
- What will you practise next?

Do not use streak or reflection design to pressure the user into longer sessions. Keep practice fictional and educational.

---

## 4. Recommended release order

### Beginner release

1. Poker foundations.
2. Decision framework.
3. Position and starting-hand ranges.
4. Hand strength and draws.
5. Board textures.
6. Bet purpose and simple sizing.
7. Basic responses to bets.
8. Full-hand review.

### Intermediate release

1. Three-betting and blind defense.
2. Pot odds, implied odds, and equity realization.
3. Continuation betting and board interaction.
4. Turn/river planning.
5. Hand reading and blockers.
6. Opponent adjustments.
7. Stack depth and SPR.

### Advanced release

1. Range construction.
2. Polarized/merged strategies.
3. Mixed strategies and solver reference outputs.
4. Advanced river strategy.
5. Separate tournament track, including short-stack play and payout-pressure concepts.

---

## 5. How to teach the learner’s current four topics

### Position

Teach it early, before starting-hand charts. First show acting order and information advantage, then demonstrate how the same hand changes from early position to the button, then apply it to blinds and postflop decisions. Position is a recurring input to later lessons, not a one-time chapter.

### Betting ranges

Clarify which meaning the app intends:

- **Hand range:** the group of hands a player could have.
- **Betting range:** the group of hands that player chooses to bet with in a particular spot.
- **Bet size range:** the set of sizes the player may use.

Teach hand ranges first. Introduce betting ranges after value bets, bluffs, and checks are understood. Add mixed betting frequencies much later.

### Board textures

Teach texture labels as observation tools, then make learners connect a board to both players’ ranges. Avoid a lesson that only asks “is this wet or dry?” The important follow-up is “which hands improved, whose range connects, and what does that mean for the action?”

### Bet sizing

Teach why a player bets before teaching size selection. Then compare small and large bets for value, bluffs, and protection. Show how sizes change the opponent’s price, continuing range, and remaining stack. Explain sizes as context-dependent choices.

---

## 6. Content authoring template

Use this structure for each lesson:

```yaml
id: board-texture-dynamic-vs-static
module: board-texture-and-range-interaction
title: Is this board dynamic?
level: beginner
estimated_minutes: 5
prerequisites:
  - hand-strength-and-draws
learning_objectives:
  - Identify turn cards that can change the strongest hand.
  - Explain how board volatility affects betting urgency.
sections:
  - concept: Dynamic boards have more turn cards that change hand strength.
    visual: board-card-animation
  - worked_example: A two-tone connected flop with straight and flush draws.
practice:
  question_types:
    - select-improving-cards
    - choose-action
feedback:
  - Explain which cards change the board and why.
  - Accept more than one reasonable action where assumptions allow it.
takeaway: Board labels help you notice change; ranges and actions decide what to do.
```

Every scenario should state enough context to support its answer: game format, positions, effective stack, pot, board, hole cards, actions so far, and any opponent assumptions. Numerical advice should name its assumptions and should not be called “optimal” unless it is based on a validated reference solution for that spot.

---

## 7. Curriculum quality rules

- Keep one primary learning objective per lesson.
- Introduce ranges before range-vs-range advanced theory.
- Teach bet purpose before bet size.
- Teach equity intuition before equations and solver frequencies.
- Teach board texture as a connection to ranges, not as a standalone action chart.
- Bring position into preflop and postflop examples throughout the course.
- Explain poker terms in plain language the first time they appear.
- Give feedback on reasoning and assumptions, not only the chosen action.
- Accept multiple defensible actions when the scenario allows them.
- Never use the eventual runout as proof that a decision was right or wrong.
- Keep cash-game and tournament lessons distinct.
- Use fictional chips and avoid profit guarantees.

---

## 8. References for curriculum planning

These sources were consulted for topic coverage and terminology. They provide examples of educational material, not a single authoritative strategy chart.

- [PokerStars Learn: Position](https://www.pokerstars.com/poker/learn/lesson/position/) — position, acting order, and its effect on hand selection.
- [PokerStars Learn: Opening the Pot](https://www.pokerstars.com/poker/learn/lesson/opening-the-pot/) — opening ranges by position and notes that ranges may be adjusted to table conditions.
- [PokerStars Learn: Pot Odds](https://www.pokerstars.com/poker/learn/lesson/pot-odds/) — pot odds, implied odds, reverse implied odds, and factors affecting draws.
- [PokerStars Learn: Bet Sizing](https://www.pokerstars.com/poker/learn/lesson/bet-sizing/) — bet purpose, sizing, position, board texture, and opponent tendencies.
- [PokerStars Learn: What is position in poker?](https://www.pokerstars.com/poker/learn/news/what-is-position-in-poker/) — examples connecting continuation betting to board texture and ranges.

---

## 9. Handoff instruction for the app-building AI

Use this curriculum to build a sequenced learning path, not a flat list of poker articles. Each listed lesson should include a short explanation, at least one worked hand, an interactive practice item, and feedback that explains its assumptions. Implement the beginner release first with complete content. Keep advanced concepts optional, distinguish heuristics from solver-backed percentages, and connect every lesson to later daily puzzles and hand reviews.

