defmodule Zoonk.Content.HoldemCurriculum do
  @moduledoc """
  Versioned, human-editable starter lessons for the PokerDex MVP.

  The answer rubrics are explicitly marked as drafts until a poker-knowledgeable reviewer approves
  them. These fixtures seed the local development curriculum; they are not solver output.
  """

  @review_note "Development curriculum: strategy answers are drafts pending poker-knowledgeable review."

  @doc "Returns authored learning tracks and short, street-specific puzzle packs."
  def tracks do
    [
      %{
        name: "Start here: rules and hand reading",
        slug: "holdem-start-here",
        description: "Learn how a Hold’em hand works, read the board, and compare hands. #{@review_note}",
        level: :beginner,
        lessons: [
          lesson(
            "a1-table-and-hand",
            "The table and the hand",
            "Learn the flow of a six-handed Hold’em hand.",
            "A hand moves through preflop, flop, turn, and river. The button marks the dealer position; the small and big blinds post forced bets. Each player receives two private cards, then up to five shared community cards are dealt.",
            "Example: with blinds of 0.5/1 fictional big blinds, the small blind posts 0.5 and the big blind posts 1 before cards are dealt. On the flop, three community cards appear. A player may check when no bet is facing them, or bet first into the pot.",
            [
              action_question(
                "a1-check-or-bet",
                "You are first to act on the flop. No one has bet, so you may check or bet. Your hand is a pair of tens on a dry board. What is a sound beginner action?",
                "under_the_gun",
                "flop",
                ["Ts", "Td"],
                ["2c", "7h", "Ks"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking keeps weaker hands in and avoids building a large pot with a vulnerable one-pair hand."},
                  "bet" => {70, "A small value/protection bet can be reasonable, but the sizing and opponents matter."}
                },
                "With no bet facing you, check and bet are available. This is a learning heuristic, not a universal rule."
              ),
              action_question(
                "a1-facing-bet",
                "You are on the button with A♠ J♦. Everyone folds to you, but the blinds are still posted. Choose an action in a typical six-handed cash game.",
                "button",
                "preflop",
                ["As", "Jd"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {30, "Folding is very cautious with a strong hand in the last position to act."},
                  "call" => {30, "Calling is possible but often gives the blinds an easy chance to see a flop; a raise is a common first-in plan."},
                  "raise" => {100, "A raise is a common first-in plan with this strong hand and positional advantage."}
                },
                "This is a typical 100-big-blind six-handed cash-game heuristic with no special reads."
              )
            ]
          ),
          lesson(
            "a2-hand-rankings",
            "Hand rankings",
            "Compare the best five cards each player can make.",
            "Poker hands are compared by category first, then by the ranks that break ties. Use the best five cards from your two private cards and the five-card board; you do not have to use both private cards.",
            "Example: if the board is K♠ 9♠ 5♠ 2♣ 2♥ and you hold A♠ Q♠, your best five cards are a flush. A player holding K♦ J♣ has two pair, kings and twos, so the flush is stronger.",
            [
              ranking_question(
                "a2-flush",
                "The board is K♠ 9♠ 5♠ 2♣ 2♥. You hold A♠ Q♠. What is your best five-card hand?",
                ["As", "Qs"],
                ["Ks", "9s", "5s", "2c", "2h"],
                :flush,
                "Your ace-high flush uses five spades. The paired board does not beat a flush."
              ),
              ranking_question(
                "a2-kicker",
                "The board is A♣ 8♦ 8♠ 5♥ 2♣. You hold A♦ K♠. What is your best hand?",
                ["Ad", "Ks"],
                ["Ac", "8d", "8s", "5h", "2c"],
                :two_pair,
                "You use two aces and two eights, with a king kicker. The fifth card breaks ties between otherwise equal two-pair hands."
              )
            ]
          ),
          lesson(
            "a3-reading-the-board",
            "Reading the board",
            "Spot made hands and draws without assuming they are already complete.",
            "A made hand already has a poker-hand category, such as a pair or two pair. A draw needs a future community card to complete a likely stronger hand. A draw can be valuable, but it is not yet a made flush or straight.",
            "Example: with A♠ 9♠ on a flop of K♠ 6♠ 2♦, you have four spades among your cards and the board. One more spade would make a flush, so you have a flush draw—not a flush yet.",
            [
              action_question(
                "a3-draw-not-made",
                "You hold A♠ 9♠ on K♠ 6♠ 2♦. An unknown opponent checks to you. You have a strong flush draw but only ace-high right now. What is a reasonable action?",
                "button",
                "flop",
                ["As", "9s"],
                ["Ks", "6s", "2d"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking keeps the pot controlled while retaining your chance to make the flush."},
                  "bet" => {100, "A bet can combine fold equity with a strong draw; the board and opponent response matter."}
                },
                "The draw is not a made flush. Both checking and betting can be reasonable depending on ranges and sizing."
              ),
              action_question(
                "a3-pair-board",
                "You hold Q♣ J♣ on a flop of 8♦ 8♠ 3♥. No one has bet. What is a cautious action in this spot?",
                "cutoff",
                "flop",
                ["Qc", "Jc"],
                ["8d", "8s", "3h"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {100, "You currently have a pair of eights from the board with queen-jack kickers; checking is a reasonable low-risk choice."},
                  "bet" => {30, "A bet with no pair in your hand may have little value unless you have a clear bluff plan."}
                },
                "For this beginner question, focus on what the cards make now; do not assume a future improvement."
              )
            ]
          ),
          checkpoint(
            "a-checkpoint",
            "Rules and hand-reading checkpoint",
            "Combine hand ranking, board reading, and basic action vocabulary.",
            "A useful hand review starts with the exact current state: whose turn it is, whether a bet is facing you, what your best current hand is, and what still needs to improve.",
            [
              ranking_question(
                "a-check-rank",
                "The board is Q♠ J♠ T♠ 4♦ 2♣. You hold A♠ K♠. What is your best hand?",
                ["As", "Ks"],
                ["Qs", "Js", "Ts", "4d", "2c"],
                :straight_flush,
                "A♠ K♠ Q♠ J♠ T♠ make a king-high straight flush."
              ),
              action_question(
                "a-check-action",
                "On the turn, you hold 9♣ 9♦ on A♠ 7♥ 3♣ 2♠. An opponent bets 2 big blinds into a 6-big-blind pot; your remaining stack is 99. Choose a cautious beginner action.",
                "button",
                "turn",
                ["9c", "9d"],
                ["As", "7h", "3c", "2s"],
                [1, 1, 1, 1, 1, 1],
                2,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {70, "Folding a small pair to a turn bet can be a cautious choice on an ace-high board, especially without a read."},
                  "call" => {70, "Calling can be reasonable against a small bet, but the opponent's range and future plan matter."},
                  "raise" => {30, "Raising a small pair is usually difficult to justify without a specific read or bluff plan."}
                },
                "Unknown opponent; the bet size is small relative to the pot. This is a judgment question, not a single universal answer."
              ),
              ranking_question(
                "a-check-tie",
                "The board is A♣ K♦ Q♥ J♠ T♣. You hold 2♣ 3♦. What is your best hand?",
                ["2c", "3d"],
                ["Ac", "Kd", "Qh", "Js", "Tc"],
                :straight,
                "The board itself makes an ace-high straight. Your hole cards do not improve it, so another player with no better combination can tie."
              )
            ]
          )
        ]
      },
      %{
        name: "Preflop fundamentals",
        slug: "holdem-preflop",
        description: "Use position, hand categories, and prior action to make more thoughtful preflop choices. #{@review_note}",
        level: :beginner,
        lessons: [
          lesson(
            "b1-position",
            "Position: who acts when",
            "Understand why acting later gives you more information.",
            "Preflop, the action starts left of the big blind and moves around the table. After the flop, action starts with the first active seat left of the button. Early position acts with more players still to respond; late position usually has more information.",
            "Example: the button acts last after the flop. If everyone checks to the button, the button has seen that action before deciding. That information can help choose a check or a bet.",
            [
              action_question(
                "b1-button-first-in",
                "Everyone folds to you on the button. You hold A♣ 9♣ and have 100 big blinds. In a typical six-handed cash game, what is a common first-in plan?",
                "button",
                "preflop",
                ["Ac", "9c"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {30, "Folding is possible but very cautious for a suited ace on the button."},
                  "call" => {30, "A limp lets the blinds see a flop cheaply; many beginner plans prefer raising or folding in this spot."},
                  "raise" => {100, "A raise uses your late position and is a common first-in plan with a suited ace."}
                },
                "Typical six-handed cash game, 100-big-blind effective stacks, no special reads."
              ),
              action_question(
                "b1-early-position",
                "You are under the gun (first to act) with 7♣ 4♦, a weak disconnected hand. What is the most sensible default?",
                "under_the_gun",
                "preflop",
                ["7c", "4d"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {100, "Folding avoids entering a pot with a weak, disconnected hand from early position."},
                  "call" => {0, "Calling invites several players in and leaves you out of position with a weak hand."},
                  "raise" => {0, "A raise with this weak hand is an unsupported bluff in the stated beginner spot."}
                },
                "Typical six-handed cash game with no special reads; this is a beginner heuristic, not a universal range chart."
              )
            ]
          ),
          lesson(
            "b2-starting-hands",
            "Starting-hand selection",
            "Group hands by their features, then account for position and action.",
            "Starting hands differ in pair strength, high-card strength, suitedness, and connectivity. Suited cards can make a flush; connected cards can make straights. These features help, but they do not make a hand automatically playable in every position.",
            "Example: A♠ Q♠ has strong high cards and can make a flush. 7♣ 2♦ is disconnected and low. A♠ Q♠ may be a sensible raise from late position, while the weak hand is usually folded, especially early.",
            [
              action_question(
                "b2-premium-pair",
                "You are first to act preflop with Q♠ Q♦ at 100 big blinds. In a typical six-handed cash game, choose a common beginner action.",
                "under_the_gun",
                "preflop",
                ["Qs", "Qd"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {0, "Folding a strong pair gives up substantial hand value without a specific reason."},
                  "call" => {30, "Calling is possible, but it can invite several opponents and hide the strength of a strong pair."},
                  "raise" => {100, "Raising builds value and narrows the field with a strong starting pair."}
                },
                "Typical six-handed cash game at 100 big blinds; no special table reads."
              ),
              action_question(
                "b2-weak-off-suit",
                "You are in the cutoff with 8♦ 3♣. Everyone has folded to you. What is the sound default for a beginner?",
                "cutoff",
                "preflop",
                ["8d", "3c"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {100, "Folding a weak offsuit hand avoids entering with poor high-card and draw potential."},
                  "call" => {0, "Calling can bring the blinds in while leaving you with a weak hand."},
                  "raise" => {30, "Late position helps, but this hand is weak enough that a raise is not a required play."}
                },
                "Beginner baseline only; exact opening ranges vary by strategy and table conditions."
              )
            ]
          ),
          lesson(
            "b3-first-in",
            "First-in decisions",
            "Choose a clear plan when the pot has not been raised.",
            "First-in means no one has entered the pot voluntarily before you. A raise can win the blinds now, build a pot with a stronger hand, and give you initiative. Limping means calling the big blind; it can be useful in some strategies, but it is not automatically the best choice.",
            "Example: folded to you in the cutoff with A♦ T♦. A raise is a common plan in a typical six-handed cash game. With 7♣ 2♦, folding is usually the cleaner beginner plan.",
            [
              action_question(
                "b3-first-in-at",
                "The action folds to you in the cutoff. You hold A♦ T♦. What is a common first-in choice?",
                "cutoff",
                "preflop",
                ["Ad", "Td"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {30, "Folding is cautious but gives up a playable hand in late position."},
                  "call" => {30, "Limping is possible, though a raise is a common clearer plan for a playable hand."},
                  "raise" => {100, "Raising is a common first-in choice with this suited high-card hand in the cutoff."}
                },
                "Typical six-handed cash game, no special reads; exact ranges differ."
              ),
              action_question(
                "b3-raise-or-fold",
                "You are first to act with 6♠ 2♣ at 100 big blinds. Which beginner plan is clearest?",
                "under_the_gun",
                "preflop",
                ["6s", "2c"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {100, "Folding avoids building a pot with a weak hand from early position."},
                  "call" => {0, "Limping weak hands makes later decisions harder without a clear reason."},
                  "raise" => {0, "Raising this hand is an unsupported bluff under the stated beginner assumptions."}
                },
                "A raise-or-fold simplification for this weak hand in early position; it is not a rule for every hand or game."
              )
            ]
          ),
          lesson(
            "b4-facing-a-raise",
            "Facing a raise",
            "Consider position, hand strength, raise size, and effective stack.",
            "When someone raises before you, the price to continue changes. A call keeps the pot multiway more often; a re-raise (three-bet) can build value or apply pressure; folding avoids a difficult spot with a weak hand. Position and effective stack affect each choice.",
            "Example: with A♠ K♦ facing a modest raise, continuing is usually sensible. Whether to call or re-raise depends on who raised, positions, sizing, and the plan for later streets.",
            [
              action_question(
                "b4-ak-facing-open",
                "A player opens to 3 big blinds from the cutoff. You are on the button with A♠ K♦ and 100 big blinds. Choose a strong beginner response.",
                "button",
                "preflop",
                ["As", "Kd"],
                [],
                [0.5, 3, 0, 0, 0, 0],
                3,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {0, "Folding this strong hand to a modest late-position open is far too cautious without a special read."},
                  "call" => {70, "Calling keeps the raiser's weaker hands in and uses your position."},
                  "raise" => {100, "A re-raise can build value with a strong hand and position, though sizing and opponent tendencies matter."}
                },
                "Typical six-handed cash game, 100-big-blind effective stacks, no special reads."
              ),
              action_question(
                "b4-weak-facing-open",
                "An early-position player raises to 3 big blinds. You are in the big blind with 8♣ 3♦. What is the sound default?",
                "big_blind",
                "preflop",
                ["8c", "3d"],
                [],
                [0.5, 3, 0, 0, 0, 0],
                3,
                1,
                ["fold", "call", "raise"],
                %{
                  "fold" => {100, "Folding avoids defending a weak hand against an early-position range."},
                  "call" => {30, "The blind discount helps the price, but this weak offsuit hand faces a strong early range."},
                  "raise" => {0, "Re-raising a weak offsuit hand against an early open lacks a stated bluff rationale."}
                },
                "Early-position raise; 100-big-blind stacks; no opponent-specific information."
              )
            ]
          ),
          checkpoint(
            "b-checkpoint",
            "Preflop fundamentals checkpoint",
            "Combine position, hand features, and the action before you.",
            "Before acting preflop, ask: what position am I in, who has already entered, how strong are my cards, and what will I do if someone raises? These details are more useful than memorizing one chart without context.",
            [
              action_question(
                "b-check-position",
                "You are on the button with K♣ J♣. Everyone folds to you. Choose a common first-in action.",
                "button",
                "preflop",
                ["Kc", "Jc"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {30, "Folding is cautious with a connected suited high-card hand on the button."},
                  "call" => {30, "Limping is possible, but a raise is a common first-in plan."},
                  "raise" => {100, "A raise is a common plan with a playable suited broadway hand in late position."}
                },
                "Typical six-handed cash game; exact ranges vary."
              ),
              action_question(
                "b-check-facing-raise",
                "A tight player raises from early position. You are in the cutoff with 9♣ 5♦. Choose a sensible default.",
                "cutoff",
                "preflop",
                ["9c", "5d"],
                [],
                [0.5, 3, 0, 0, 0, 0],
                3,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {100, "Folding a weak offsuit hand against a tight early raise avoids a difficult dominated spot."},
                  "call" => {0, "Calling continues with a weak hand against a range described as tight."},
                  "raise" => {0, "Re-raising this hand without a specific bluff plan is not supported by the assumptions."}
                },
                "The opponent is described as tight; use that information as a tendency, not certainty."
              ),
              action_question(
                "b-check-premium",
                "You are first to act with A♠ A♥. What is a common action at 100 big blinds?",
                "under_the_gun",
                "preflop",
                ["As", "Ah"],
                [],
                [0.5, 1, 0, 0, 0, 0],
                1,
                0,
                ["fold", "call", "raise"],
                %{
                  "fold" => {0, "Folding the strongest starting pair gives up substantial value."},
                  "call" => {30, "Calling can disguise strength, but often misses value and invites more players."},
                  "raise" => {100, "Raising builds value and is a common straightforward plan with pocket aces."}
                },
                "A beginner baseline; advanced strategies may include some calls in specific situations."
              )
            ]
          )
        ]
      },
      %{
        name: "Flop decisions",
        slug: "holdem-flop-decisions",
        description: "Classify your hand, read the board, and choose a flop plan with stated assumptions. #{@review_note}",
        level: :beginner,
        lessons: [
          lesson(
            "c1-made-draw-air",
            "Made hand, draw, or air",
            "Name what your hand is now before planning what it might become.",
            "A made hand already has a category. A draw needs future cards to improve. Air is a hand with little current showdown value and no strong draw. Overcards are private cards higher than the board cards; they may improve, but are not a pair yet.",
            "Example: A♠ Q♠ on K♠ 6♠ 2♦ is ace-high with a flush draw. It is not a flush. 9♣ 8♦ on the same board has little immediate value and no spade draw.",
            [
              action_question(
                "c1-top-pair",
                "You raised preflop with A♣ K♦. The flop is K♠ 7♥ 2♣ and an opponent checks. You have top pair with a strong kicker. What is a reasonable plan?",
                "button",
                "flop",
                ["Ac", "Kd"],
                ["Ks", "7h", "2c"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking can control the pot while keeping weaker hands in the range."},
                  "bet" => {100, "A value bet can be called by worse pairs and can protect against overcards."}
                },
                "Heads-up, relatively dry board, unknown opponent. Both actions can be reasonable by strategy and sizing."
              ),
              action_question(
                "c1-air",
                "You hold 9♣ 8♦ on A♠ K♥ 3♣. You raised preflop and the big blind called. The opponent checks. What is a sound cautious choice?",
                "button",
                "flop",
                ["9c", "8d"],
                ["As", "Kh", "3c"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {100, "Checking with little showdown value avoids an automatic bluff on a board that can favor the caller."},
                  "bet" => {30, "A bluff may work sometimes, but this hand has little equity and the ace-high board can connect with the caller."}
                },
                "Heads-up pot; unknown opponent; the board is ace-high and relatively disconnected. Avoid treating a continuation bet as automatic."
              )
            ]
          ),
          lesson(
            "c2-board-texture",
            "Board texture",
            "Notice how connected and suited cards change possible hands.",
            "A dry board has fewer immediate draws. A connected or wet board has more straight and flush possibilities. A paired board contains a repeated rank. These descriptions help identify possibilities; they do not dictate one automatic action.",
            "Example: A♣ 7♦ 2♠ is relatively dry. J♠ T♠ 8♦ is more connected and has a flush draw. On the second board, more turn cards can change hand strength.",
            [
              action_question(
                "c2-dry-value",
                "You hold A♠ K♦ on A♣ 7♦ 2♠, a dry board. An opponent checks to you. What is a reasonable value-oriented choice?",
                "button",
                "flop",
                ["As", "Kd"],
                ["Ac", "7d", "2s"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking keeps the pot smaller and may induce later bluffs."},
                  "bet" => {100, "A modest value bet can be called by weaker aces and pairs while denying some overcard equity."}
                },
                "Heads-up on a dry board; no special opponent read. Bet sizing remains a strategic choice."
              ),
              action_question(
                "c2-wet-board",
                "You hold Q♥ Q♣ on J♠ T♠ 8♦. This board is connected and can change quickly. The opponent checks. What deserves more weight?",
                "button",
                "flop",
                ["Qh", "Qc"],
                ["Js", "Ts", "8d"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking can control the pot with one pair on a connected board."},
                  "bet" => {100, "A protection/value bet can deny equity and get calls from draws, but the board is risky."}
                },
                "One-pair hand on a wet board; both choices can be reasonable depending on sizing and opponent range."
              )
            ]
          ),
          lesson(
            "c3-board-advantage",
            "Who benefits from the board?",
            "Connect the preflop action and ranges to the flop.",
            "A range is the group of hands a player could have. Range advantage means one player's possible hands fit the board better overall. Nut advantage means one player is more likely to hold the strongest possible hands. Neither idea proves what a specific opponent holds.",
            "Example: a preflop raiser may have more high pairs on A♣ 7♦ 2♠ than a big blind caller. On 8♠ 7♠ 6♦, the caller may have more low and connected hands. These are broad tendencies, not certainty.",
            [
              action_question(
                "c3-ace-high",
                "You raised from the button and the big blind called. On A♣ 7♦ 2♠, you hold K♠ Q♠ and the big blind checks to you. A small continuation bet is a common heuristic for which reason?",
                "button",
                "flop",
                ["Ks", "Qs"],
                ["Ac", "7d", "2s"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking is allowed; it can preserve equity and avoid betting every hand automatically."},
                  "bet" => {100, "The preflop raiser often has more strong aces and overpairs on this dry ace-high board, supporting a small range bet heuristic."}
                },
                "The preflop raiser has a likely range advantage on this board; this does not mean every hand should bet."
              ),
              action_question(
                "c3-low-connected",
                "The button raised and you called in the big blind. The flop is 8♠ 7♠ 6♦. You hold A♣ 2♦ and act first. What is a sensible first thought?",
                "big_blind",
                "flop",
                ["Ac", "2d"],
                ["8s", "7s", "6d"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {100, "This connected board can fit the caller's range; with little made value, checking is a sound default."},
                  "bet" => {30, "A bluff is possible, but this hand has limited equity and the board interacts with many caller hands."}
                },
                "The caller may have more connected combinations here. Ranges are groups of possibilities, not exact hands."
              )
            ]
          ),
          lesson(
            "c4-continuation-bet",
            "Continuation betting",
            "Choose a bet for a reason, and know when checking helps.",
            "A continuation bet is a flop bet by the player who raised preflop. It can be for value, protection, or as a bluff. Checking can control the pot, realize equity, or avoid a weak bluff. The preflop raiser does not need to bet every flop.",
            "Example: top pair may bet because worse hands can call. A strong draw may bet to combine fold equity and improvement chances. A weak hand on a board that favors the caller may check.",
            [
              action_question(
                "c4-value-cbet",
                "You raised preflop with A♥ Q♦ and were called by the big blind. The flop is Q♠ 8♣ 3♦. The big blind checks. What is a sensible purpose for betting?",
                "button",
                "flop",
                ["Ah", "Qd"],
                ["Qs", "8c", "3d"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking can protect your checking range and keep weaker hands in."},
                  "bet" => {100, "A value bet can be called by worse queens and pairs; it also denies some overcard equity."}
                },
                "Heads-up on a dry board; top pair. Bet size depends on the range and plan."
              ),
              action_question(
                "c4-check-back",
                "You raised preflop with 6♣ 5♣ and were called by the big blind. On A♠ K♦ 2♥, the big blind checks. What is a sound beginner plan?",
                "button",
                "flop",
                ["6c", "5c"],
                ["As", "Kd", "2h"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" =>
                    {100, "Checking avoids an automatic bluff with little equity. Although the preflop raiser may have a range advantage, you do not need to bet every flop."},
                  "bet" => {30, "A bet can represent strength, but this hand has few immediate ways to improve and no clear value."}
                },
                "Unknown opponent; low-equity hand. Bluffing can be part of a plan, but should have a reason."
              )
            ]
          ),
          checkpoint(
            "c-checkpoint",
            "Flop decisions checkpoint",
            "Use your hand, the board, and the preflop story together.",
            "At a flop decision, name your made hand or draw, describe the board, and ask which ranges connect with it. Then choose a bet or check with a purpose. These are learning heuristics under assumptions, not solver guarantees.",
            [
              action_question(
                "c-check-draw",
                "You hold 9♠ 8♠ on 7♠ 6♦ 2♠. You have a flush draw and an open-ended straight draw. An opponent checks. What are two possible reasons to bet?",
                "button",
                "flop",
                ["9s", "8s"],
                ["7s", "6d", "2s"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {70, "Checking preserves equity and can keep the pot controlled; it is a reasonable alternative."},
                  "bet" => {100, "Betting can combine fold equity with multiple ways to improve when called."}
                },
                "Strong combo draw; no bet is facing you. Bet and check may both be used in a balanced strategy."
              ),
              action_question(
                "c-check-one-pair",
                "You hold J♦ J♣ on A♠ 9♥ 4♣ after raising preflop. The big blind checks. What is a cautious default?",
                "button",
                "flop",
                ["Jd", "Jc"],
                ["As", "9h", "4c"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {100, "Checking keeps the pot manageable with second pair and avoids being raised off a showdown hand."},
                  "bet" => {70, "A small protection bet can be reasonable, but worse hands may not call often on an ace-high board."}
                },
                "One pair below the ace; unknown opponent. The check is a cautious heuristic, not the only valid line."
              ),
              action_question(
                "c-check-air",
                "You hold 7♣ 6♦ on K♠ Q♥ 2♣ after raising preflop. The caller checks. What should a beginner avoid?",
                "button",
                "flop",
                ["7c", "6d"],
                ["Ks", "Qh", "2c"],
                [1, 1, 1, 1, 1, 1],
                0,
                0,
                ["check", "bet"],
                %{
                  "check" => {100, "Checking is preferable to bluffing automatically with little equity on a board that can hit the caller."},
                  "bet" => {30, "A bluff may work with a reason, but betting every flop simply because you raised preflop is not sound."}
                },
                "No meaningful draw and no special read. A continuation bet is not automatic."
              )
            ]
          )
        ]
      }
    ] ++ street_puzzle_tracks()
  end

  defp street_puzzle_tracks do
    [
      puzzle_track(
        "Preflop",
        "holdem-puzzles-preflop",
        "Pick a preflop spot and make a plan from your seat and the action so far.",
        [
          puzzle_lesson(
            "puzzle-preflop-1",
            "First in from the small blind",
            action_question(
              "puzzle-preflop-1",
              "Folds to you in the small blind with K♣ T♣. What is a sensible first-in action?",
              "small_blind",
              "preflop",
              ["Kc", "Tc"],
              [],
              [0, 0, 0, 0, 0.5, 1],
              1,
              0.5,
              ["fold", "call", "raise"],
              %{
                "fold" => {30, "Folding is too tight for a suited king when action folds to you."},
                "call" => {70, "Completing is a reasonable low-cost option, though it lets the big blind see a flop cheaply."},
                "raise" => {100, "Raising takes the initiative with a strong suited hand and can win the blinds immediately."}
              },
              "Six-handed cash example, 100-big-blind effective stacks, action folds to the small blind, and there are no special reads."
            )
          ),
          puzzle_lesson(
            "puzzle-preflop-2",
            "Defend the big blind",
            action_question(
              "puzzle-preflop-2",
              "An opponent opens to 2.5 big blinds. You are in the big blind with Q♣ J♣. Choose a reasonable response.",
              "big_blind",
              "preflop",
              ["Qc", "Jc"],
              [],
              [0.5, 2.5, 0, 0, 0, 1],
              2.5,
              1,
              ["fold", "call", "raise"],
              %{
                "fold" => {70, "Folding can be reasonable if you prefer a tighter defense."},
                "call" => {100, "Calling keeps a playable suited hand in at a discounted price."},
                "raise" => {70, "A re-raise can also be used, depending on your strategy and the opener."}
              },
              "Six-handed cash example, 100-big-blind effective stacks, no special reads."
            )
          )
        ]
      ),
      puzzle_track(
        "Flop",
        "holdem-puzzles-flop",
        "Read the board and decide whether to check or bet on the flop.",
        [
          puzzle_lesson(
            "puzzle-flop-1",
            "Top pair on a dry flop",
            action_question(
              "puzzle-flop-1",
              "You hold Q♥ J♦ on Q♠ 8♣ 3♦. The big blind checks. What is a sensible plan?",
              "button",
              "flop",
              ["Qh", "Jd"],
              ["Qs", "8c", "3d"],
              [1, 1, 1, 1, 1, 1],
              0,
              0,
              ["check", "bet"],
              %{
                "check" => {70, "Checking keeps the pot manageable and can protect your checking range."},
                "bet" => {100, "A value bet can get calls from worse pairs and charge overcards."}
              },
              "Heads-up, relatively dry board, unknown opponent. Both actions can be reasonable by strategy and sizing."
            )
          ),
          puzzle_lesson(
            "puzzle-flop-2",
            "Combo draw on a wet flop",
            action_question(
              "puzzle-flop-2",
              "You hold 9♠ 8♠ on 7♠ 6♦ 2♠. The opponent checks. What is a reasonable aggressive option?",
              "button",
              "flop",
              ["9s", "8s"],
              ["7s", "6d", "2s"],
              [1, 1, 1, 1, 1, 1],
              0,
              0,
              ["check", "bet"],
              %{
                "check" => {70, "Checking preserves your equity and keeps the pot smaller."},
                "bet" => {100, "Betting can combine fold equity with a flush draw and open-ended straight draw."}
              },
              "Heads-up, no bet is facing you. This combo draw can support aggression, but checking remains viable."
            )
          )
        ]
      ),
      puzzle_track(
        "Turn",
        "holdem-puzzles-turn",
        "Reassess your hand and draws after the fourth community card.",
        [
          puzzle_lesson(
            "puzzle-turn-1",
            "Top pair facing a small bet",
            action_question(
              "puzzle-turn-1",
              "You hold Q♦ J♦ on Q♠ 7♣ 2♥ 4♦. The opponent bets 2 into 6. What is a reasonable response?",
              "button",
              "turn",
              ["Qd", "Jd"],
              ["Qs", "7c", "2h", "4d"],
              [1, 1, 1, 1, 1, 1],
              2,
              0,
              ["fold", "call", "raise"],
              %{
                "fold" => {30, "Folding top pair to a small turn bet is cautious without a strong read."},
                "call" => {100, "Calling keeps bluffs and weaker hands in while protecting your one-pair hand from a large pot."},
                "raise" => {30, "Raising can isolate yourself against stronger hands unless you have a clear value reason."}
              },
              "Heads-up, modest turn bet, unknown opponent, 100-big-blind effective stacks."
            )
          ),
          puzzle_lesson(
            "puzzle-turn-2",
            "Open-ended draw on the turn",
            action_question(
              "puzzle-turn-2",
              "You hold J♠ T♠ on Q♠ 9♣ 4♦ 2♥. The opponent checks. What can a bet accomplish?",
              "button",
              "turn",
              ["Js", "Ts"],
              ["Qs", "9c", "4d", "2h"],
              [1, 1, 1, 1, 1, 1],
              0,
              0,
              ["check", "bet"],
              %{
                "check" => {70, "Checking takes your free card and keeps the pot controlled."},
                "bet" => {100, "Betting can create folds now while your open-ended straight draw can still improve."}
              },
              "Heads-up, Hero raised preflop, opponent checked on the turn. A semi-bluff is a choice, not a rule."
            )
          )
        ]
      ),
      puzzle_track(
        "River",
        "holdem-puzzles-river",
        "Make a final decision with the full board and no cards left to come.",
        [
          puzzle_lesson(
            "puzzle-river-1",
            "Value bet the nut flush",
            action_question(
              "puzzle-river-1",
              "You hold A♦ Q♦ on K♦ 8♦ 3♦ J♣ 2♠. The opponent checks. What is a reasonable value action?",
              "button",
              "river",
              ["Ad", "Qd"],
              ["Kd", "8d", "3d", "Jc", "2s"],
              [1, 1, 1, 1, 1, 1],
              0,
              0,
              ["check", "bet"],
              %{
                "check" => {70, "Checking locks in showdown but may miss calls from weaker hands."},
                "bet" => {100, "Your ace-high flush is very strong; betting can earn calls from lower flushes and other hands."}
              },
              "River checked to Hero; no special opponent read. Choose a size that can be called by worse hands."
            )
          ),
          puzzle_lesson(
            "puzzle-river-2",
            "Missed draw, check or bluff?",
            action_question(
              "puzzle-river-2",
              "You hold K♠ Q♠ on A♠ 8♠ 4♦ 2♥ J♦. The opponent checks. What is the cautious choice?",
              "button",
              "river",
              ["Ks", "Qs"],
              ["As", "8s", "4d", "2h", "Jd"],
              [1, 1, 1, 1, 1, 1],
              0,
              0,
              ["check", "bet"],
              %{
                "check" => {100, "Checking keeps your showdown value after the flush draw missed."},
                "bet" => {70, "A bluff may fold some better hands, but it needs a credible target and line."}
              },
              "The spade draw missed. No read suggests the opponent will fold; checking is the low-risk option."
            )
          )
        ]
      ),
      puzzle_track(
        "Showdown",
        "holdem-puzzles-showdown",
        "Read the final board and compare the best five cards.",
        [
          puzzle_lesson(
            "puzzle-showdown-1",
            "Two pair from the board",
            ranking_question(
              "puzzle-showdown-1",
              "You hold A♦ Q♣ on A♣ 8♦ 8♠ 5♥ 2♣. What is your best hand category?",
              ["Ad", "Qc"],
              ["Ac", "8d", "8s", "5h", "2c"],
              :two_pair,
              "Your ace pairs with the board ace, and the board pair of eights gives you two pair: aces and eights."
            )
          ),
          puzzle_lesson(
            "puzzle-showdown-2",
            "Full house on a paired board",
            ranking_question(
              "puzzle-showdown-2",
              "You hold K♦ 2♦ on 9♣ 9♦ 9♥ K♠ 4♣. What is your best hand category?",
              ["Kd", "2d"],
              ["9c", "9d", "9h", "Ks", "4c"],
              :full_house,
              "You use three nines from the board and a pair of kings from your hand and the board to make a full house."
            )
          )
        ]
      )
    ]
  end

  defp puzzle_track(title, slug, description, lessons) do
    %{
      name: "#{title} puzzles",
      slug: slug,
      description: description,
      level: :beginner,
      lessons: lessons
    }
  end

  defp puzzle_lesson(id, name, question) do
    id
    |> lesson(name, "Quick #{String.downcase(name)} puzzle.", "", "", [question])
    |> Map.put(:puzzle_only?, true)
  end

  @doc "Returns the teaching-first theory curriculum, separate from the puzzle tracks."
  def theory_tracks, do: Zoonk.Content.HoldemTheoryCurriculum.tracks()

  @doc "Returns both the teaching curriculum and authored practice tracks."
  def all_tracks, do: theory_tracks() ++ tracks()

  defp lesson(id, name, description, objective, example, questions) do
    %{
      id: id,
      name: name,
      description: description,
      objective: objective,
      example: example,
      questions: questions,
      difficulty: puzzle_difficulty(id),
      checkpoint?: false
    }
  end

  defp checkpoint(id, name, description, objective, questions) do
    %{
      id: id,
      name: name,
      description: description,
      objective: objective,
      example: "Worked example: pause before deciding, list the information you have, then apply the relevant rule or heuristic.",
      questions: questions,
      difficulty: puzzle_difficulty(id),
      checkpoint?: true
    }
  end

  defp puzzle_difficulty(id)
       when id in [
              "b4-facing-a-raise",
              "b-checkpoint",
              "c3-board-advantage",
              "c4-continuation-bet",
              "c-checkpoint",
              "puzzle-preflop-2",
              "puzzle-flop-2",
              "puzzle-turn-2",
              "puzzle-river-2",
              "puzzle-showdown-2"
            ], do: :intermediate

  defp puzzle_difficulty(_id), do: :beginner

  defp action_question(id, prompt, position, street, hole_cards, board, contributions, street_bet, hero_contribution, actions, rubric, assumption) do
    seat = position_seat(position)
    contributions = normalized_contributions(street, contributions, seat, street_bet, hero_contribution)
    hero_committed = Enum.at(contributions, seat - 1)
    amount_to_call = max(street_bet - hero_contribution, 0)
    pot = Enum.sum(contributions)

    options =
      Enum.map(actions, fn action ->
        {score, feedback} = Map.fetch!(rubric, action)

        %{
          title: action |> String.replace("_", " ") |> String.capitalize(),
          score: score,
          score_label: score_label(score),
          correct?: score >= 70,
          feedback: feedback
        }
      end)

    scenario = %{
      "scenario_id" => id,
      "version" => if(id == "puzzle-preflop-1", do: 2, else: 1),
      "status" => "draft",
      "format" => "six_max_cash",
      "table" => %{"seat_count" => 6, "button_seat" => 4, "players_in_hand" => 2},
      "hero" => %{
        "seat" => seat,
        "position" => position,
        "starting_stack_bb" => 100,
        "remaining_stack_bb" => 100 - hero_committed,
        "hole_cards" => hole_cards
      },
      "effective_stack_bb" => 100,
      "blinds" => %{"small_blind" => 0.5, "big_blind" => 1, "ante" => 0, "straddle" => 0},
      "street" => street,
      "board" => board,
      "pot" => pot,
      "action_history" => action_history(street, position, street_bet),
      "action_state" => %{
        "amount_to_call_bb" => amount_to_call,
        "street_bet_bb" => street_bet,
        "hero_street_contribution_bb" => hero_contribution,
        "contributions_by_seat_bb" => contributions
      },
      "legal_actions" => actions,
      "question" => %{"type" => "choose_action", "prompt" => prompt},
      "assumptions" => [assumption, "All chip amounts are fictional big blinds."],
      "skill_tags" => [skill_tag(id)],
      "answer_key" => %{"rubric" => Enum.map(options, &Map.take(&1, [:title, :score, :score_label, :feedback]))}
    }

    %{content: prompt, kind: :quiz, poker_scenario: scenario, options: options}
  end

  defp ranking_question(id, prompt, hole_cards, board, category, rationale) do
    option_categories = [:high_card, :one_pair, :two_pair, :three_of_a_kind, :straight, :flush, :full_house, :four_of_a_kind, :straight_flush]

    options =
      Enum.map(option_categories, fn option_category ->
        correct? = option_category == category

        %{
          title: category_title(option_category),
          correct?: correct?,
          score: if(correct?, do: 100, else: 0),
          score_label: if(correct?, do: "Correct", else: "Review"),
          feedback: if(correct?, do: rationale, else: "Review the five best cards together, then compare the hand category.")
        }
      end)

    scenario = %{
      "scenario_id" => id,
      "version" => 1,
      "status" => "draft",
      "format" => "six_max_cash",
      "table" => %{"seat_count" => 6, "button_seat" => 4, "players_in_hand" => 2},
      "hero" => %{
        "seat" => 4,
        "position" => "button",
        "starting_stack_bb" => 100,
        "remaining_stack_bb" => 100,
        "hole_cards" => hole_cards
      },
      "effective_stack_bb" => 100,
      "blinds" => %{"small_blind" => 0.5, "big_blind" => 1, "ante" => 0, "straddle" => 0},
      "street" => "river",
      "board" => board,
      "pot" => 10,
      "action_history" => [],
      "legal_actions" => [],
      "question" => %{"type" => "hand_ranking", "prompt" => prompt},
      "assumptions" => ["Use the best five cards available from the hole cards and board."],
      "skill_tags" => ["rules.hand_ranking"],
      "answer_key" => %{"category" => Atom.to_string(category), "rationale" => rationale}
    }

    %{content: prompt, kind: :quiz, poker_scenario: scenario, options: options}
  end

  defp lesson_steps(%{puzzle_only?: true} = lesson) do
    lesson.questions ++ [%{content: "Hand complete. Review the feedback, then try another spot.", kind: :readonly}]
  end

  defp lesson_steps(lesson) do
    intro_steps = readonly_steps(lesson.objective)
    teaching_steps = Enum.flat_map(Map.get(lesson, :teaching, []), &readonly_steps/1)
    worked_example_steps = readonly_steps("Worked example: #{lesson.example}")

    finish = %{
      content: "Lesson complete. Recall the key idea and how it helps you understand a hand.",
      kind: :readonly
    }

    intro_steps ++ teaching_steps ++ worked_example_steps ++ lesson.questions ++ [finish]
  end

  defp readonly_steps(content) do
    content
    |> readable_chunks()
    |> Enum.map(&%{content: &1, kind: :readonly})
  end

  defp readable_chunks(content) do
    sentences =
      content
      |> String.split(~r/(?<=[.!?])\s+/, trim: true)
      |> Enum.flat_map(&split_long_sentence/1)

    {chunks, current} =
      Enum.reduce(sentences, {[], nil}, fn sentence, {chunks, current} ->
        candidate = if current, do: current <> " " <> sentence, else: sentence

        if String.length(candidate) <= 250 do
          {chunks, candidate}
        else
          {[current | chunks], sentence}
        end
      end)

    Enum.reverse(if(current, do: [current | chunks], else: chunks))
  end

  defp split_long_sentence(sentence) when byte_size(sentence) <= 250, do: [sentence]

  defp split_long_sentence(sentence) do
    {chunks, current} =
      sentence
      |> String.split(~r/\s+/, trim: true)
      |> Enum.reduce({[], ""}, fn word, {chunks, current} ->
        candidate = if current == "", do: word, else: current <> " " <> word

        if String.length(candidate) <= 250 do
          {chunks, candidate}
        else
          {[current | chunks], word}
        end
      end)

    Enum.reverse(if(current == "", do: chunks, else: [current | chunks]))
  end

  defp score_label(100), do: "Strong"
  defp score_label(70), do: "Reasonable"
  defp score_label(30), do: "Questionable"
  defp score_label(_score), do: "Major error"

  defp category_title(:high_card), do: "High card"
  defp category_title(:one_pair), do: "One pair"
  defp category_title(:two_pair), do: "Two pair"
  defp category_title(:three_of_a_kind), do: "Three of a kind"
  defp category_title(:straight), do: "Straight"
  defp category_title(:flush), do: "Flush"
  defp category_title(:full_house), do: "Full house"
  defp category_title(:four_of_a_kind), do: "Four of a kind"
  defp category_title(:straight_flush), do: "Straight flush"

  defp position_seat("under_the_gun"), do: 1
  defp position_seat("hijack"), do: 2
  defp position_seat("cutoff"), do: 3
  defp position_seat("button"), do: 4
  defp position_seat("small_blind"), do: 5
  defp position_seat("big_blind"), do: 6

  defp normalized_contributions("preflop", _contributions, hero_seat, street_bet, hero_contribution) do
    contributions = [0, 0, 0, 0, 0.5, 1]
    contributions = List.replace_at(contributions, hero_seat - 1, hero_contribution)

    if street_bet > 1 do
      raiser_seat = if hero_seat == 1, do: 2, else: 1
      List.replace_at(contributions, raiser_seat - 1, street_bet)
    else
      contributions
    end
  end

  defp normalized_contributions(_street, contributions, hero_seat, _street_bet, _hero_contribution) do
    List.replace_at(contributions, hero_seat - 1, 1)
  end

  defp action_history("preflop", _position, street_bet) when street_bet > 1 do
    ["An opponent raised to #{street_bet} big blinds; action is on Hero."]
  end

  defp action_history("preflop", _position, _street_bet) do
    ["The small and big blinds are posted; no one has entered voluntarily before Hero."]
  end

  defp action_history("turn", _position, street_bet) when street_bet > 0 do
    ["Preflop: Hero called. The flop checked through. An opponent bet #{street_bet} big blinds on the turn; action is on Hero."]
  end

  defp action_history(_street, "big_blind", _street_bet) do
    ["Preflop: the button raised and Hero called. The flop action is on Hero."]
  end

  defp action_history(_street, _position, street_bet) when street_bet > 0 do
    ["Preflop: Hero raised and an opponent called. The opponent bet #{street_bet} big blinds; action is on Hero."]
  end

  defp action_history(_street, _position, _street_bet) do
    ["Preflop: Hero raised and an opponent called. The opponent checked to Hero."]
  end

  defp skill_tag("puzzle-preflop-" <> _), do: "preflop.fundamentals"
  defp skill_tag("puzzle-flop-" <> _), do: "flop.decisions"
  defp skill_tag("puzzle-turn-" <> _), do: "turn.decisions"
  defp skill_tag("puzzle-river-" <> _), do: "river.decisions"
  defp skill_tag("a" <> _), do: "rules.hand_reading"
  defp skill_tag("b" <> _), do: "preflop.fundamentals"
  defp skill_tag("c" <> _), do: "flop.decisions"

  @doc "Adds ordered lesson-step payloads to each lesson fixture."
  def lesson_with_steps(lesson), do: Map.put(lesson, :steps, lesson_steps(lesson))
end
