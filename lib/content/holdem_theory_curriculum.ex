defmodule Zoonk.Content.HoldemTheoryCurriculum do
  @moduledoc "Topic-led Hold’em curriculum ordered from beginner foundations to advanced study."

  defp fundamentals_by_street do
    [
      track(
        :preflop,
        "Preflop",
        "theory-preflop",
        "Learn how a hand begins, how position shapes your options, and how to think before the flop.",
        [
          lesson(
            :beginner,
            "p1-hand-start",
            "A hand begins",
            "Learn the button, blinds, private cards, and first action.",
            [
              "The dealer button marks the nominal dealer. Before cards are dealt, the next player left of the button posts the small blind and the following player posts the big blind. These forced bets create a pot to play for. Each player then receives two private hole cards.",
              "Preflop action begins with the first player left of the big blind and moves clockwise. A player can fold, call the amount needed to match the current bet, or raise. Action continues until every active player has matched the highest bet or folded. If everyone folds to one player, that player wins without a flop."
            ],
            "At blinds of 0.5 and 1 fictional big blinds, the small blind posts 0.5 and the big blind posts 1. The first player left of the big blind acts. If they fold and everyone else folds, the big blind wins the posted blinds.",
            [
              check(
                "What does the big blind do before the cards are dealt?",
                "Posts a forced bet.",
                ["Deals the flop.", "Chooses the first preflop action."],
                "The big blind posts a forced bet before the hand begins. Preflop action starts to the big blind’s left."
              ),
              check(
                "When does a hand end before any community cards are dealt?",
                "When everyone but one player folds.",
                ["After the first player calls.", "Only after the river."],
                "A hand can end whenever all other players fold. The remaining player wins the pot without needing to show cards."
              )
            ]
          ),
          lesson(
            :beginner,
            "p2-position",
            "Position and action order",
            "See how acting later gives you more information.",
            [
              "Position describes where you act relative to the button. Preflop, the first player left of the big blind acts first and the big blind acts last if still in the hand. After the flop, action starts with the first active player left of the button. The button is therefore last to act postflop when it has not folded.",
              "Acting later lets you see more decisions before making your own. A check, bet, or raise can reveal information about how an opponent is approaching the hand. Early position has less information and more players still to act, so the same hand can be harder to play there. Position helps frame a decision; it does not make a weak hand automatically strong."
            ],
            "On the flop, three players remain. The first player checks and the second checks. The button has now seen both actions before deciding. If the button had acted first, those checks would not yet be known.",
            [
              check(
                "Who usually acts last after the flop when still in the hand?",
                "The button.",
                ["The small blind in every hand.", "The first player left of the button."],
                "Postflop action proceeds clockwise from the first active seat left of the button, so the button usually acts last."
              ),
              check(
                "Why can late position be useful?",
                "You can observe more actions before deciding.",
                ["You always receive stronger cards.", "You do not have to respond to bets."],
                "Position changes the information available to you. It does not change the cards or remove the need to respond to action."
              )
            ]
          ),
          lesson(
            :intermediate,
            "p3-action-and-ranges",
            "Action before the flop",
            "Distinguish entering first from responding to a raise.",
            [
              "If no one has voluntarily entered the pot, you are choosing whether to fold, call the blind, or raise first. If someone has raised, you are responding to a different price and to a range that is usually stronger than a random hand. A call, re-raise, or fold should be considered in that context.",
              "A range is the set of hands a player could reasonably hold after taking an action. You rarely know an opponent’s exact cards. Think in possible groups of hands, using their position and earlier choices as evidence. This avoids treating one guess as a fact and helps explain why a decision changes when the action changes."
            ],
            "If everyone folds to the button, the button may choose a first-in raise with a wider group of hands than a player acting first. If an early player has already raised, the button should account for that stronger action before deciding whether to continue.",
            [
              check(
                "What changes when a player has already raised before you?",
                "The amount to call and the likely range you are facing.",
                ["Your position at the table.", "The number of community cards."],
                "The prior raise changes both the price of continuing and the range represented by the raiser."
              ),
              check(
                "What does a range describe?",
                "A group of hands a player could hold.",
                ["The exact two cards an opponent has.", "The order the community cards are dealt."],
                "A range represents plausible hands, since you usually cannot know an opponent’s exact cards."
              )
            ]
          ),
          lesson(
            :advanced,
            "p4-stack-and-plan",
            "Stacks and a preflop plan",
            "Connect the decision now with the later streets.",
            [
              "Your remaining stack limits how much you can invest and win from each opponent. The effective stack is the smaller relevant stack between players contesting a pot. A large preflop raise can make the pot grow quickly and leave less behind for later streets, so consider the whole hand rather than treating the opening decision in isolation.",
              "A useful preflop plan names your position, the action already taken, the price to continue, and what kinds of flops may help your hand. Beginners can use reviewed starting-hand charts as a guide, but charts depend on game format, position, and prior action. Do not treat a chart as a universal answer for every table."
            ],
            "With 100 big blinds effective, an early-position raise is called by the button. The hand goes to the flop with a larger pot and both players still have chips behind. The preflop action and the button’s position help shape what each range can contain on the flop.",
            [
              check(
                "What is the effective stack between two players?",
                "The smaller stack that limits what they can win from each other.",
                ["The larger stack at the table.", "The total chips in the pot."],
                "The smaller relevant stack limits the amount either player can win from the other in that pot."
              ),
              check(
                "Why should a preflop plan consider later streets?",
                "The pot and remaining stacks affect future decisions.",
                ["Community cards are already known.", "A preflop hand cannot change after the flop."],
                "Preflop betting affects the pot size and remaining stacks, which matter on the flop, turn, and river."
              )
            ]
          )
        ]
      ),
      track(
        :flop,
        "Flop",
        "theory-flop",
        "Read the first three community cards, recognise draws, and make a reasoned plan.",
        [
          lesson(
            :beginner,
            "f1-the-flop",
            "The first three cards",
            "Learn what the flop adds and how the next betting round works.",
            [
              "The flop is three community cards dealt face up after the preflop betting round. Every remaining player shares these cards. Players use their two private cards and the board to make the best five-card hand available; they do not have to use both private cards.",
              "After the flop, a new betting round begins. The first active player left of the button acts first. A player may check if no bet is facing them, or bet. Once a bet is made, later players can fold, call, or raise. The round ends when the remaining players have matched the bets or all but one have folded."
            ],
            "The flop is K♠ 8♠ 4♦. It gives every player the same three board cards. A player holding K♦ 7♣ currently has a pair of kings, while a player with A♠ Q♠ has a flush draw, not a completed flush.",
            [
              check("How many cards are revealed on the flop?", "Three.", ["One.", "Four."], "The flop is the first three community cards."),
              check(
                "Who acts first after the flop?",
                "The first active player left of the button.",
                ["The button always acts first.", "The big blind in every hand."],
                "Postflop action starts with the first active seat left of the button."
              )
            ]
          ),
          lesson(
            :beginner,
            "f2-made-hands-and-draws",
            "Made hands and draws",
            "Separate what your cards make now from what could arrive later.",
            [
              "A made hand already has a category such as a pair, two pair, or a straight. A draw still needs a future community card to complete a likely stronger hand. The distinction matters because a draw can improve but has not yet made the hand it is chasing.",
              "Count the cards carefully. On a two-tone flop, a player holding two cards of that suit has four cards toward a flush and needs one more. A straight draw has connected ranks that can be completed by certain ranks. Some draws have more completing cards than others, and an opponent may share or dominate your draw."
            ],
            "With A♠ 9♠ on K♠ 6♠ 2♦, you have four spades among your private cards and the flop. You have a flush draw. The hand is still ace-high until a spade arrives and your best five-card hand changes.",
            [
              check(
                "Four spades among your hole cards and flop make what?",
                "A flush draw.",
                ["A completed flush.", "A straight."],
                "You need a fifth spade among the community cards to complete the flush."
              ),
              check(
                "What is a made hand?",
                "A hand that already has a poker-hand category.",
                ["A hand that needs a future card to improve.", "Any two suited hole cards."],
                "A made hand already has a category. A draw still needs a future card."
              )
            ]
          ),
          lesson(
            :intermediate,
            "f3-board-texture",
            "Board texture",
            "Describe how ranks and suits create possible hands and draws.",
            [
              "Board texture describes how the community cards relate to one another. A paired board repeats a rank. A connected board has nearby ranks that can support straight draws. A two-tone board has two cards of one suit; a monotone flop has three. A dry board offers fewer obvious draws, while a coordinated board has more possible ways to improve.",
              "Texture is a map of possibilities, not a prediction of an opponent’s exact hand. Ask which hands connect strongly, which draws exist, and whether the turn can change the board significantly. The same pair may be comfortable on a dry board and vulnerable on a board with many straight and flush draws."
            ],
            "On 9♠ 8♠ 7♦, connected ranks and two spades create straight and flush possibilities. On A♣ 7♦ 2♠, the ranks are disconnected and the suits are different. The first board is more coordinated, though the action and players’ ranges still matter.",
            [
              check(
                "What does a paired board have?",
                "Two or more community cards of the same rank.",
                ["Two cards of the same suit only.", "Five connected community cards."],
                "A paired board repeats a rank among the community cards."
              ),
              check(
                "Why is a connected two-tone flop coordinated?",
                "It can support both straight and flush draws.",
                ["It guarantees a straight for one player.", "It means every player has a flush."],
                "Nearby ranks and two cards of one suit create possible draws, but do not guarantee anyone has made them."
              )
            ]
          ),
          lesson(
            :advanced,
            "f4-range-and-action",
            "Plan the flop action",
            "Use the board and preflop action to choose a reason for betting or checking.",
            [
              "Before acting, recall who raised preflop, who called, and where each player sits. Those actions suggest different ranges. Compare those ranges with the flop: which player has more strong made hands here, and which player has more draws? These are estimates based on actions, not certainties.",
              "A bet can seek calls from worse hands, make better hands fold, protect a vulnerable hand, or build a pot. A check can control the pot, keep weaker hands in, or conceal your hand. Bet size changes the price offered and the pot you may play later. Choose a reason and a size that fit the board, opponents, and remaining stacks instead of betting automatically."
            ],
            "A preflop raiser holds A♦ K♣ on K♥ 7♠ 2♣ after one player calls. The raiser has top pair on a relatively dry board and may bet for value or check to control the pot. The caller’s response and the chosen size affect the turn plan.",
            [
              check(
                "What should give a flop bet a clear purpose?",
                "A reason tied to value, folds, protection, or the next-street plan.",
                ["The fact that you raised preflop by itself.", "The need to bet every time you have a pair."],
                "A bet should have a reason in the spot; being the preflop raiser alone does not require a continuation bet."
              ),
              check(
                "What can a check do with a vulnerable one-pair hand?",
                "Keep the pot smaller while retaining the hand’s showdown value.",
                ["Guarantee the hand wins at showdown.", "Prevent the turn from being dealt."],
                "Checking can control the pot, though it does not guarantee the hand will win."
              )
            ]
          )
        ]
      ),
      track(
        :turn,
        "Turn",
        "theory-turn",
        "Reassess the hand when the fourth community card changes the board and pot.",
        [
          lesson(
            :beginner,
            "t1-turn-card",
            "The fourth community card",
            "Learn how the turn is dealt and how action continues.",
            [
              "The turn is the fourth community card. It is dealt after the flop betting round and followed by another betting round. As on the flop, the first active player left of the button acts first. The board is now more complete, but one final community card can still arrive.",
              "A turn card can improve your hand, pair the board, or complete a draw. Look at all four community cards together with your hole cards, then compare them with the flop and the action so far. Do not assume that a card helped you simply because you like it, or that it helped an opponent without evidence."
            ],
            "The flop is Q♥ 9♣ 4♥ and the turn is 2♥. The board now has three hearts. A player with two hearts in their hand has made a flush; a player with one heart has a flush draw. The river can still change the result.",
            [
              check("How many community cards are on the board after the turn?", "Four.", ["Three.", "Five."], "The turn adds the fourth community card."),
              check("How many cards remain to be dealt after the turn?", "One: the river.", ["Two.", "None."], "The river is the only community card left after the turn.")
            ]
          ),
          lesson(
            :beginner,
            "t2-recheck-your-hand",
            "Recheck your hand",
            "Compare your current hand with what the new board allows.",
            [
              "After the turn, identify your best current five-card hand and compare it with the full board. Check whether the card paired a rank, made a possible straight or flush, or changed which hands are strongest. A hand’s label may stay the same while its relative strength changes.",
              "Separate made hands from draws again. A draw that completed is now a made hand. A draw that missed still has one chance on the river. Some turn cards create new draws as well as completing old ones. This careful recount is more reliable than remembering only that your hand was strong on the flop."
            ],
            "You hold Q♠ J♠ on Q♥ 9♣ 4♥ 2♥. You still have a pair of queens, but three hearts are on the board. Your pair has not disappeared; the number of possible flushes has increased, so the action deserves a fresh look.",
            [
              check(
                "What should you do when the turn changes the board texture?",
                "Reassess your hand and the possible hands in both ranges.",
                ["Continue the flop plan without reviewing it.", "Assume every opponent completed a draw."],
                "The turn can change hand strength and draw possibilities, so review the new state without assuming exact cards."
              ),
              check("A draw misses the turn. How many community cards can still complete it?", "One, the river.", ["Two.", "None."], "After the turn, only the river remains.")
            ]
          ),
          lesson(
            :intermediate,
            "t3-pot-and-price",
            "Pot size and price",
            "Relate the bet you face to the pot and remaining stacks.",
            [
              "When facing a turn bet, note the pot before the bet, the bet size, and the amount you must call. Calling adds chips to the pot and keeps you in the hand; folding gives up your claim to it. The price matters alongside the chance your hand is best or can improve, and the opponent’s possible range.",
              "The remaining effective stack also shapes the decision. A large pot with a short stack behind may lead to a different river situation from a small pot with deep stacks. You do not need complex math to start: state the pot, the price, your hand or draw, and what you expect on the river before choosing."
            ],
            "The pot is 8 big blinds and an opponent bets 4. You must call 4 to continue. If you call, the pot will be 16 before any further river action. Compare that price with your hand, draw, and the opponent’s likely range rather than looking only at the bet in isolation.",
            [
              check(
                "Why compare a turn bet with the pot?",
                "It shows the price of continuing relative to what is already at stake.",
                ["It reveals the opponent’s exact hand.", "It determines the next community card."],
                "The pot and bet size help describe the price to continue, but they do not reveal exact cards."
              ),
              check(
                "What is the effective stack useful for understanding?",
                "How much more can be contested between the players.",
                ["How many cards are in the deck.", "Which seat acts first."],
                "The effective stack limits how much remains to play for between the players in the pot."
              )
            ]
          ),
          lesson(
            :advanced,
            "t4-turn-plan",
            "Plan for the river",
            "Choose turn actions with the final card and likely responses in mind.",
            [
              "A turn bet should connect to what you want the river to look like. With a strong hand, consider which worse hands may call and which draws can continue. With a draw, consider the chance to improve, the price, and whether a bet can also make some better hands fold. With a medium-strength hand, checking may keep the pot manageable.",
              "Think through likely responses before acting: what will you do if called, raised, or checked to on the river? This prevents investing on the turn without a plan. The answer depends on board, ranges, size, and stacks; these questions guide thought rather than prescribe a universal line."
            ],
            "You bet a strong top pair on a turn that completes a flush draw and get called. Before betting, it helps to know which river cards you can value bet, which make you cautious, and how you will respond to a raise. The river plan can affect whether the turn bet is worthwhile.",
            [
              check(
                "What is a useful question before betting the turn?",
                "What will I do if called, raised, or checked to on the river?",
                ["Can I avoid seeing the river?", "Will this bet force every opponent to fold?"],
                "Thinking ahead makes the turn decision part of a coherent hand plan."
              ),
              check(
                "Is one turn action correct on every board?",
                "No; the board, ranges, bet size, and stacks matter.",
                ["Yes, always bet top pair.", "Yes, always check a draw."],
                "Turn decisions depend on the full situation, not one hand label alone."
              )
            ]
          )
        ]
      ),
      track(
        :river,
        "River",
        "theory-river",
        "Make final-street decisions when no more community cards can improve a hand.",
        [
          lesson(
            :beginner,
            "r1-river-card",
            "The final community card",
            "Recognise that the river completes the board.",
            [
              "The river is the fifth and final community card. Once it is dealt, there are no more cards to improve anyone’s hand. Re-evaluate your best five cards, the completed board, and the action on the flop and turn.",
              "Notice which draws completed and which missed, but do not assign an exact hand from the card alone. An opponent can have a made hand, a missed draw, or another holding. Use their actions, position, and the board to estimate possibilities."
            ],
            "The river board is A♣ 9♦ 6♠ 4♥ 2♣. A♦ K♦ makes a pair of aces. A heart draw has missed, but that does not prove an opponent with earlier heart-suited action is bluffing.",
            [
              check("How many more community cards come after the river?", "None.", ["One.", "Two."], "The river is the fifth and final community card."),
              check(
                "Does a missed draw prove that an opponent is bluffing?",
                "No; it is one possibility among the hands they could hold.",
                ["Yes, every missed draw must bluff.", "Yes, because the board is complete."],
                "The board does not reveal exact cards. A missed draw may bluff or give up, depending on the player and action."
              )
            ]
          ),
          lesson(
            :beginner,
            "r2-value",
            "Value betting",
            "Understand when a bet can be called by worse hands.",
            [
              "A value bet aims to be called by a worse hand. Before betting, name the weaker hands that could plausibly reach the river and might call. If no worse hand is likely to call, the bet may not be for value even if your hand looks strong.",
              "The bet size affects which hands can continue. A small bet may invite more calls from marginal hands; a large bet may be called only by stronger holdings. Opponents differ, so use the line and player tendencies you have observed rather than assuming they all respond the same way."
            ],
            "You hold A♠ Q♣ on A♦ 8♥ 5♣ 3♠ 2♦. If a weaker ace or a pair may call a modest bet, betting can seek value. If only better hands call a large bet, checking may keep the pot from growing when you are behind.",
            [
              check(
                "What is the basic aim of a value bet?",
                "To get called by a worse hand.",
                ["To make every better hand fold.", "To see another community card."],
                "A value bet hopes a worse hand will call."
              ),
              check(
                "What should you identify before making a value bet?",
                "Worse hands that could call.",
                ["The exact cards in every opponent’s hand.", "A guaranteed win."],
                "A value bet needs plausible calls from worse hands; no bet guarantees a win."
              )
            ]
          ),
          lesson(
            :intermediate,
            "r3-bluffs",
            "Bluffs and missed draws",
            "Use a reason to represent a strong hand rather than bluffing automatically.",
            [
              "A bluff tries to make a better hand fold. A missed draw can be a candidate because it may have little showdown value, but bluffing still needs a credible story and a target. Consider what strong hands your earlier actions represent and whether the river card fits that range.",
              "A bluff is less attractive when the opponent is unlikely to fold, the board favors their range, or your bet does not threaten enough. Checking with a missed draw can also be sensible. Selecting a bluff is about the situation and opponent, not just noticing that your own draw failed."
            ],
            "You raised preflop and bet a K♠ 8♦ 3♣ flop and 2♥ turn. The river is A♣. That ace may fit some strong hands in your range, but whether to bluff depends on the opponent, prior sizing, and how often they can hold a hand willing to fold.",
            [
              check(
                "What is the goal of a bluff?",
                "To make a better hand fold.",
                ["To get called by a worse hand.", "To improve on the next card."],
                "A bluff seeks folds from hands that currently beat yours."
              ),
              check(
                "Why is a missed draw not automatically a good bluff?",
                "The opponent may not fold, and the story may not fit the action.",
                ["Because missed draws cannot win pots.", "Because the river is always a check."],
                "A bluff needs a credible line and a target likely to fold; the missed draw alone is not enough."
              )
            ]
          ),
          lesson(
            :advanced,
            "r4-calling-decisions",
            "Calling and bluff-catching",
            "Decide whether the opponent’s range contains enough bluffs for a call.",
            [
              "When facing a river bet, your hand may be strong enough to beat bluffs but lose to value hands. Such a call is a bluff-catch. Ask what value hands the opponent can have after the earlier action, what missed draws can bluff, and whether the bet size makes those bluffs plausible.",
              "A bigger bet asks you to risk more to win the pot, so the price changes. Use the pot and call amount, then compare that price with how often you expect to be ahead. Exact answers depend on ranges and behavior; if the evidence is uncertain, say what assumption your decision relies on."
            ],
            "The pot is 10 big blinds and an opponent bets 5. You must call 5 to contest the pot. If their line contains many missed draws, a bluff-catch may be reasonable; if it mostly contains strong value hands, folding can be better. The board and prior actions help estimate that mix.",
            [
              check(
                "What does a bluff-catch beat?",
                "Bluffs, while losing to the opponent’s value hands.",
                ["Every value hand.", "Only a future card."],
                "A bluff-catcher is a call with a hand that beats bluffs but loses to value bets."
              ),
              check(
                "What is the river call amount compared with?",
                "The pot and the range of hands that could bet.",
                ["Only your original starting hand.", "The number of players who folded preflop."],
                "The price and the opponent’s likely range are both relevant to a river call."
              )
            ]
          )
        ]
      ),
      track(
        :showdown,
        "Showdown",
        "theory-showdown",
        "Compare the best hands, understand ties and side pots, and see how a hand ends.",
        [
          lesson(
            :beginner,
            "s1-when-showdown",
            "When a hand reaches showdown",
            "Learn when players reveal cards and when the pot is won earlier.",
            [
              "If every opponent folds, the last player remaining wins the pot immediately. A showdown is not needed. If at least two players remain after the river betting round, they compare their hands to determine the winner.",
              "Showdown procedure can vary by room. Commonly, the player who made the last aggressive action on the river shows first; if the river checked through, the first active player left of the button shows first. Players then reveal in turn. Follow the house procedure, and do not assume a player must reveal if all others have already mucked and conceded."
            ],
            "On the river, Player A bets and Player B folds. Player A wins the pot without showing. If Player B calls instead, both remain eligible and their hands are compared at showdown.",
            [
              check(
                "When is showdown unnecessary?",
                "When every opponent folds and one player remains.",
                ["Whenever there was a river bet.", "Only before the flop."],
                "A player who wins because everyone else folded does not need to show a hand."
              ),
              check(
                "What happens after a river bet is called?",
                "The remaining hands are compared at showdown.",
                ["The caller automatically wins.", "A sixth community card is dealt."],
                "If at least two players remain after the river action, their hands are compared."
              )
            ]
          ),
          lesson(
            :beginner,
            "s2-best-five",
            "Choose the best five cards",
            "Use any combination of private and community cards to make one hand.",
            [
              "Texas Hold’em uses the best five cards available from seven: your two private cards and the five community cards. You may use both private cards, one, or neither. The board can play as the best five cards for everyone, which can result in a tie.",
              "The hand categories, from lower to higher, are high card, one pair, two pair, three of a kind, straight, flush, full house, four of a kind, and straight flush. Compare category first. Within the same category, compare the ranks that make the hand and then any relevant kickers. Suits do not rank hands."
            ],
            "The board is A♣ K♦ Q♥ J♠ T♣. It already makes an ace-high straight. If neither player can make a higher category, a player’s private cards do not improve that board hand and the players tie.",
            [
              check(
                "How many cards make the hand compared at showdown?",
                "The best five available.",
                ["All seven cards.", "Exactly both hole cards and three board cards."],
                "The best five cards can come from any combination of the private cards and board."
              ),
              check(
                "Do suits break a tie between otherwise equal hands?",
                "No.",
                ["Yes, spades always win.", "Yes, hearts always win."],
                "Suits do not break ties in standard Texas Hold’em hand rankings."
              )
            ]
          ),
          lesson(
            :intermediate,
            "s3-kickers-and-board",
            "Kickers and a shared board",
            "Compare hands carefully when categories are the same.",
            [
              "When two players have the same hand category, compare the ranks that form it. If those match, compare the next highest unused card, called a kicker. For one pair, compare the pair rank first, then the highest kickers in order. Do not compare all hole cards automatically; only the best five-card hand counts.",
              "Sometimes the board itself supplies the best five cards. In that case, players with no improvement share the same hand. A private card that appears high does not win a tie unless it changes one of the best five cards. Carefully choose each player’s best five before deciding who wins."
            ],
            "The board is A♣ A♦ K♠ 8♥ 3♣. Player 1 holds Q♠ J♠ and Player 2 holds T♠ 9♠. Both have a pair of aces from the board. Player 1’s queen kicker beats Player 2’s ten kicker, so Player 1 wins.",
            [
              check(
                "When two players have the same pair, what may decide the winner?",
                "The best remaining kickers.",
                ["The suit of the pair.", "Who acted first preflop."],
                "After matching the pair, compare the highest remaining cards in each player’s best five-card hand."
              ),
              check(
                "If the board is the best five cards for both players, what can happen?",
                "They can tie and split the pot.",
                ["The button automatically wins.", "The player with more private cards wins."],
                "If neither player improves on the shared board, they have the same hand and tie."
              )
            ]
          ),
          lesson(
            :advanced,
            "s4-ties-and-side-pots",
            "Ties, side pots, and the next hand",
            "Understand how eligible pots are awarded and how play moves on.",
            [
              "Players with equal best hands split the pot they are eligible to win. If an all-in player has fewer chips than other players, side pots can form. A player can win only the main pot and side pots they contributed to; they cannot win chips from a side pot they were not eligible to contest. The dealer or house procedure awards each pot separately.",
              "After the pot is awarded, the hand is over. The button moves to the next seat and the blinds move with it for the next hand. Before the next deal, verify the pot award and remaining stacks. Understanding the full hand includes how money returns to the players, not just who had the strongest cards."
            ],
            "Player A is all-in for 20 chips, while Players B and C each contribute 50. A can win the main pot built from the first 20 chips each contributed. B and C contest the additional side pot between them. If A wins the main pot, A does not receive the side pot.",
            [
              check(
                "Can an all-in player win a side pot they did not contribute to?",
                "No; they can win only pots they were eligible to contest.",
                ["Yes, every pot at the table.", "Only if they have the dealer button."],
                "A player cannot win a side pot they were not eligible to contest."
              ),
              check(
                "What moves after a hand is complete?",
                "The button advances and the blinds move for the next hand.",
                ["The community cards become the next player’s hole cards.", "The same player remains the button forever."],
                "The button and blinds advance to the next seats before the next hand is dealt."
              )
            ]
          )
        ]
      )
    ]
  end

  @doc "Returns the topic modules in the recommended learning order."
  def tracks, do: modules()

  def modules do
    lessons_by_id =
      fundamentals_by_street()
      |> Enum.flat_map(& &1.lessons)
      |> Map.new(&{&1.id, &1})

    [
      module(
        0,
        :beginner,
        "Poker foundations",
        "theory-module-00-foundations",
        "Understand the hand, legal actions, hand rankings, and how the board is used.",
        :rules,
        lessons_by_id,
        ["p1-hand-start", "f1-the-flop", "s1-when-showdown", "s2-best-five", "s3-kickers-and-board", "s4-ties-and-side-pots"]
      ),
      module(
        1,
        :beginner,
        "How to think about decisions",
        "theory-module-01-decisions",
        "Use the information available at the decision point and compare the trade-offs of each action.",
        :decisions,
        lessons_by_id,
        [],
        [decision_framework_lesson()]
      ),
      module(
        2,
        :beginner,
        "Position and preflop ranges",
        "theory-module-02-preflop",
        "Learn how seat, prior action, and starting-hand groups shape a preflop choice.",
        :preflop,
        lessons_by_id,
        ["p2-position", "p3-action-and-ranges"]
      ),
      module(
        3,
        :beginner,
        "Hand strength, draws, and equity",
        "theory-module-03-equity",
        "Separate made hands from draws and estimate how they perform as the hand develops.",
        :equity,
        lessons_by_id,
        ["f2-made-hands-and-draws", "t2-recheck-your-hand"]
      ),
      module(
        4,
        :beginner,
        "Board texture and range interaction",
        "theory-module-04-boards",
        "Connect board features to the hands and draws each player could hold.",
        :boards,
        lessons_by_id,
        ["f3-board-texture", "f4-range-and-action"]
      ),
      module(
        5,
        :beginner,
        "Betting purpose and bet sizing",
        "theory-module-05-betting",
        "Understand why to bet, then consider how size changes the price and future pot.",
        :betting,
        lessons_by_id,
        ["r2-value", "r3-bluffs"],
        [bet_sizing_lesson()]
      ),
      module(
        6,
        :beginner,
        "Responding to bets",
        "theory-module-06-responses",
        "Compare folding, calling, and raising using the bet, pot, and opponent’s possible range.",
        :responses,
        lessons_by_id,
        ["r4-calling-decisions", "t3-pot-and-price"],
        [response_framework_lesson()]
      ),
      module(
        7,
        :beginner,
        "Turn and river planning",
        "theory-module-07-later-streets",
        "Reassess new cards and plan how the hand can continue through the final decision.",
        :later_streets,
        lessons_by_id,
        ["t1-turn-card", "t4-turn-plan", "r1-river-card"]
      ),
      module(
        8,
        :intermediate,
        "Hand reading, ranges, and blockers",
        "theory-module-08-hand-reading",
        "Narrow groups of possible hands using action, board cards, and card removal.",
        :ranges,
        lessons_by_id,
        ["p4-stack-and-plan"]
      ),
      module(
        9,
        :intermediate,
        "Opponent tendencies and adjustments",
        "theory-module-09-opponents",
        "Use observed behavior carefully and adjust without treating a tendency as certainty.",
        :opponents,
        lessons_by_id,
        []
      ),
      module(
        10,
        :intermediate,
        "Stack depth and pot geometry",
        "theory-module-10-stacks",
        "See how effective stacks and pot size shape the decisions still to come.",
        :stacks,
        lessons_by_id,
        []
      ),
      module(
        11,
        :intermediate,
        "Integrated hand analysis",
        "theory-module-11-integrated",
        "Combine position, ranges, board, sizing, and action in complete hand reviews.",
        :integrated,
        lessons_by_id,
        []
      ),
      module(
        12,
        :advanced,
        "Advanced strategy concepts",
        "theory-module-12-advanced",
        "Explore range construction, frequencies, and model-based strategy with clear assumptions.",
        :advanced,
        lessons_by_id,
        []
      ),
      module(
        13,
        :beginner,
        "Decision discipline and review",
        "theory-module-13-review",
        "Review choices without hindsight and use mistakes to choose focused practice.",
        :review,
        lessons_by_id,
        [],
        [review_lesson()]
      )
    ]
  end

  defp module(order, level, name, slug, description, topic, lessons_by_id, lesson_ids, extra_lessons \\ []) do
    lessons =
      Enum.map(Enum.map(lesson_ids, &Map.fetch!(lessons_by_id, &1)) ++ extra_lessons, &Map.put(&1, :difficulty, level))

    %{
      order: order,
      topic: topic,
      name: name,
      slug: slug,
      description: description,
      level: level,
      curriculum_street: nil,
      curriculum_stage: nil,
      lessons: lessons
    }
  end

  defp decision_framework_lesson do
    lesson(
      :beginner,
      "decision-framework-five-questions",
      "Ask five questions before acting",
      "Use position, action, pot, ranges, and purpose to organise a decision.",
      [
        "A poker decision depends on the information available now. Start with your position and the action before you. Then note the pot, effective stack, and amount you must call. Estimate the hands each player could have from their position and choices. Finally, state what you want your action to achieve.",
        "These questions do not produce one automatic answer. They make your reasoning clearer and show which assumptions could change your choice. A check can keep the pot smaller, a call can continue against bluffs, and a raise can seek value or folds; each also has costs and risks."
      ],
      "You are on the button with a pair of eights after an early-position raise and one call. Before choosing, identify the raiser’s position, the price, the players still behind, and how the pair may play after the flop. The same pair can call, raise, or fold in different setups.",
      [
        check(
          "Which detail should you establish before choosing an action?",
          "The action and price facing you.",
          ["The next community card.", "The opponent’s exact hidden cards."],
          "Only use information available at the decision. Future cards and exact hidden holdings are not known."
        ),
        check(
          "Why state the purpose of a bet?",
          "It helps connect the action to value, folds, protection, or a plan.",
          ["It guarantees the opponent will respond as expected.", "It makes position irrelevant."],
          "A clear purpose helps evaluate whether a bet fits the spot, though it does not guarantee a result."
        )
      ]
    )
  end

  defp bet_sizing_lesson do
    lesson(
      :beginner,
      "bet-sizing-purpose-and-price",
      "Bet size changes the decision",
      "Compare a size with the pot, your goal, and the hands that may continue.",
      [
        "A bet size is usually described relative to the pot. A bet of 3 into 6 is half-pot; a bet of 6 into 6 is pot-sized. Larger bets risk more chips and give the opponent a worse price to continue, while smaller bets risk less and can be called more widely.",
        "Choose a purpose before choosing a size. For value, ask which worse hands can call. As a bluff, ask which better hands may fold and how much you risk to win the pot. Board texture, position, ranges, effective stacks, and opponent tendencies all affect the choice. No single size works everywhere."
      ],
      "The pot is 8 big blinds and you are considering a bet of 4. That is half-pot. Before betting, name your purpose and the hands you expect to call or fold. A different board or opponent can make another size or a check more reasonable.",
      [
        check("A bet of 4 into a pot of 8 is what fraction of the pot?", "Half-pot.", ["Quarter-pot.", "Twice the pot."], "Four is half of eight, so this is a half-pot bet."),
        check(
          "What should guide your bet size?",
          "Your purpose, the ranges, the board, and the remaining stacks.",
          ["A rule to use the same size on every board.", "The suit of your highest card alone."],
          "Sizing depends on the situation and the job you want the bet to do."
        )
      ]
    )
  end

  defp response_framework_lesson do
    lesson(
      :beginner,
      "fold-call-raise-framework",
      "Choose how to respond to a bet",
      "Use the price, your hand, and the opponent’s possible hands to compare fold, call, and raise.",
      [
        "When a bet faces you, folding ends your involvement and avoids further cost. Calling pays the price to continue and may keep bluffs or weaker hands in the opponent’s range. Raising can seek value, make some hands fold, or use a draw with room to improve, but it risks more chips.",
        "Start with the pot and amount to call, then estimate the range that could bet. Consider your position, hand or draw, effective stack, and what you expect if you continue. A small bet does not mean you must defend every hand, and a large bet does not prove the opponent has a monster."
      ],
      "The pot is 10 big blinds and an opponent bets 5. You must call 5 to continue. Compare that price with your hand and the opponent’s likely range; the bet size alone does not decide whether you should call.",
      [
        check(
          "What does calling do?",
          "Pays the amount required to continue in the hand.",
          ["Ends your hand immediately.", "Guarantees you will see the river for free."],
          "Calling matches the current bet, but later betting rounds may still require more chips."
        ),
        check(
          "What information should help decide whether to continue?",
          "The call price and the hands the opponent could have.",
          ["Only the last card that will be dealt.", "A guess at one exact holding treated as certain."],
          "Use the price and a range of plausible hands rather than claiming certainty about hidden cards."
        )
      ]
    )
  end

  defp review_lesson do
    lesson(
      :beginner,
      "decision-review-without-hindsight",
      "Review the decision, not just the result",
      "Separate what you knew when you acted from what the later cards revealed.",
      [
        "A good decision can lose and a poor decision can win. When reviewing a hand, pause at the original decision and hide every card that had not been dealt yet. Write down the position, action, price, likely ranges, and your reason before looking at the outcome.",
        "Then check whether your reasoning used relevant evidence and stated its assumptions. If a choice felt uncertain, review that concept with another hand rather than treating one result as proof."
      ],
      "You call a flop bet with a draw, but the river does not complete it. The missed draw does not by itself make the flop call wrong. Review the price and estimated chance to improve that were available on the flop.",
      [
        check(
          "When should you reveal the later cards during a decision review?",
          "After recording the reasoning available at the decision point.",
          ["Before choosing an action.", "Use the river to decide whether the flop action was right."],
          "Hide future cards first to avoid judging an earlier choice with information that was not available."
        ),
        check(
          "What does a single lost hand prove about a decision?",
          "Nothing by itself; review the information and assumptions at the time.",
          ["That the action is always wrong.", "That the opponent had the exact hand you imagined."],
          "Short-term outcomes vary. Review the choice using the evidence available then."
        )
      ]
    )
  end

  defp track(street, name, slug, description, lessons) do
    %{
      name: name,
      slug: slug,
      description: description,
      curriculum_street: street,
      level: :beginner,
      lessons: lessons
    }
  end

  defp lesson(difficulty, id, name, description, teaching, example, questions) do
    %{
      id: id,
      name: name,
      description: description,
      objective: description,
      teaching: teaching,
      example: example,
      questions: questions,
      difficulty: difficulty,
      checkpoint?: false
    }
  end

  defp check(prompt, answer, distractors, rationale) do
    options =
      distractors
      |> List.insert_at(1, answer)
      |> Enum.map(fn title ->
        correct? = title == answer

        %{
          title: title,
          correct?: correct?,
          score: if(correct?, do: 100, else: 0),
          score_label: if(correct?, do: "Correct", else: "Review"),
          feedback: if(correct?, do: rationale, else: "Review the lesson explanation, then consider the information available at this point in the hand.")
        }
      end)

    %{content: prompt, kind: :quiz, options: options}
  end
end
