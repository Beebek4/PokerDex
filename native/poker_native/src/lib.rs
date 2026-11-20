use rs_poker::arena::game_state::{GameState, Round, RoundData};
use rs_poker::arena::{Agent, GameStateBuilder, HoldemSimulationBuilder, agent::CallingAgent};
use rs_poker::core::{Deck, FlatHand, Hand, PlayerBitSet, Rankable};
use rustler::{Error, NifResult, Resource, ResourceArc};
use std::sync::Mutex;

struct GameSession {
    state: Mutex<GameState>,
    deck: Mutex<Deck>,
    outcome: Mutex<HandOutcome>,
}

#[derive(Clone, Copy)]
enum HandOutcome {
    InProgress,
    FoldWinner(usize),
    ShowdownWinner(usize),
    Tie,
}

#[rustler::resource_impl]
impl Resource for GameSession {}

#[derive(rustler::NifStruct)]
#[module = "Elixir.Zoonk.Poker.Native.GameView"]
struct GameView {
    round: String,
    acting_player: usize,
    human_action_enabled: bool,
    pot: f32,
    to_call: f32,
    min_raise: f32,
    max_raise: f32,
    hero_stack: f32,
    bot_stack: f32,
    winner: Option<usize>,
    is_tie: bool,
    hero_cards: Vec<String>,
    bot_cards: Vec<String>,
    board: Vec<String>,
    best_five: Vec<String>,
}

#[rustler::nif]
fn rank_hand(cards: String) -> NifResult<String> {
    let hand = FlatHand::new_from_str(&cards).map_err(|_| Error::BadArg)?;
    Ok(format!("{:?}", hand.rank().category()))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn simulate_calling_agents() -> NifResult<String> {
    let game_state = GameStateBuilder::new()
        .num_players_with_stack(2, 100.0)
        .blinds(10.0, 5.0)
        .build()
        .map_err(|_| Error::BadArg)?;

    let agents: Vec<Box<dyn Agent>> = vec![
        Box::<CallingAgent>::default(),
        Box::<CallingAgent>::default(),
    ];
    let mut simulation = HoldemSimulationBuilder::default()
        .game_state(game_state)
        .agents(agents)
        .build()
        .map_err(|_| Error::BadArg)?;

    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .map_err(|_| Error::BadArg)?;
    runtime.block_on(simulation.run());

    Ok(format!("{:?}", simulation.game_state.round))
}

#[rustler::nif]
fn start_human_hand(
    hero_total: f32,
    bot_total: f32,
) -> NifResult<(ResourceArc<GameSession>, GameView)> {
    if !hero_total.is_finite() || !bot_total.is_finite() || hero_total <= 5.0 || bot_total <= 10.0 {
        return Err(Error::BadArg);
    }

    let mut deck = Deck::default();
    let mut rng = rand::rng();
    let hero_hand = deal_hand(&mut deck, &mut rng)?;
    let bot_hand = deal_hand(&mut deck, &mut rng)?;

    // Heads-up: hero is the button/small blind and acts first preflop.
    let mut round_data = RoundData::new_with_bets(10.0, PlayerBitSet::new(2), 0, vec![5.0, 10.0]);
    round_data.total_raise_count = 0;
    round_data.forced_bet_count = 2;
    let state = GameStateBuilder::new()
        .stacks([hero_total - 5.0, bot_total - 10.0])
        .blinds(10.0, 5.0)
        .dealer_idx(0)
        .round(Round::Preflop)
        .hands([hero_hand, bot_hand])
        .player_bet([5.0, 10.0])
        .round_data(round_data)
        .build()
        .map_err(|_| Error::BadArg)?;

    let session = ResourceArc::new(GameSession {
        state: Mutex::new(state),
        deck: Mutex::new(deck),
        outcome: Mutex::new(HandOutcome::InProgress),
    });
    let view = snapshot(&session)?;

    Ok((session, view))
}

/// Apply a human action between Elixir calls, then let the call/check bot act
/// until the next human turn or showdown. A raise amount is the total
/// contribution this street, not the additional chips being put in.
#[rustler::nif]
fn human_action(
    session: ResourceArc<GameSession>,
    action: String,
    amount: f32,
) -> NifResult<GameView> {
    let mut state = session.state.lock().map_err(|_| Error::BadArg)?;

    if !is_betting_round(state.round) || state.to_act_idx() != 0 || state.is_complete() {
        return Err(Error::BadArg);
    }

    match action.as_str() {
        "fold" => {
            state.fold();
            let pot = state.total_pot;
            state.award(1, pot);
            state.complete();
            let mut outcome = session.outcome.lock().map_err(|_| Error::BadArg)?;
            *outcome = HandOutcome::FoldWinner(1);
            return Ok(snapshot_locked(&state, *outcome));
        }
        "call" => {
            let call_amount = state.current_round_bet();
            state
                .do_bet(call_amount, false)
                .map_err(|_| Error::BadArg)?;
        }
        "check" => {
            if state.current_round_player_bet(0) < state.current_round_bet() {
                return Err(Error::BadArg);
            }
            let current_bet = state.current_round_bet();
            state
                .do_bet(current_bet, false)
                .map_err(|_| Error::BadArg)?;
        }
        "raise" => {
            if !amount.is_finite() {
                return Err(Error::BadArg);
            }
            let current_contribution = state.current_round_player_bet(0);
            let bot_contribution = state.current_round_player_bet(1);
            if amount - current_contribution >= state.current_player_stack()
                || amount - bot_contribution >= state.stacks[1]
            {
                // This proof does not implement all-in runouts or side pots.
                return Err(Error::BadArg);
            }
            state.do_bet(amount, false).map_err(|_| Error::BadArg)?;
        }
        _ => return Err(Error::BadArg),
    }

    let mut deck = session.deck.lock().map_err(|_| Error::BadArg)?;
    let mut outcome = session.outcome.lock().map_err(|_| Error::BadArg)?;
    advance_until_human_turn(&mut state, &mut deck, &mut outcome)?;
    Ok(snapshot_locked(&state, *outcome))
}

fn advance_until_human_turn(
    state: &mut GameState,
    deck: &mut Deck,
    outcome: &mut HandOutcome,
) -> NifResult<()> {
    for _ in 0..40 {
        if state.is_complete() {
            return Ok(());
        }

        if state.current_round_num_active_players() == 0 {
            state.advance_round();
            match state.round {
                Round::DealFlop => {
                    deal_community_cards(state, deck, 3)?;
                    state.advance_round();
                }
                Round::DealTurn | Round::DealRiver => {
                    deal_community_cards(state, deck, 1)?;
                    state.advance_round();
                }
                Round::Showdown => {
                    settle_showdown(state, outcome)?;
                    return Ok(());
                }
                Round::Complete => return Ok(()),
                _ => {}
            }
            continue;
        }

        if state.to_act_idx() == 0 {
            return Ok(());
        }

        // The prototype bot checks when free and calls when facing a bet.
        let call_amount = state.current_round_bet();
        state
            .do_bet(call_amount, false)
            .map_err(|_| Error::BadArg)?;
    }

    Err(Error::BadArg)
}

fn deal_community_cards(state: &mut GameState, deck: &mut Deck, count: usize) -> NifResult<()> {
    let mut rng = rand::rng();
    for _ in 0..count {
        state.board.push(deck.deal(&mut rng).ok_or(Error::BadArg)?);
    }
    Ok(())
}

fn settle_showdown(state: &mut GameState, outcome: &mut HandOutcome) -> NifResult<()> {
    let hero_rank = rank_player_hand(state, 0)?;
    let bot_rank = rank_player_hand(state, 1)?;
    let pot = state.total_pot;

    match hero_rank.cmp(&bot_rank) {
        std::cmp::Ordering::Greater => {
            state.award(0, pot);
            *outcome = HandOutcome::ShowdownWinner(0);
        }
        std::cmp::Ordering::Less => {
            state.award(1, pot);
            *outcome = HandOutcome::ShowdownWinner(1);
        }
        std::cmp::Ordering::Equal => {
            state.award(0, pot / 2.0);
            state.award(1, pot / 2.0);
            *outcome = HandOutcome::Tie;
        }
    }

    state.complete();
    Ok(())
}

fn rank_player_hand(state: &GameState, player_idx: usize) -> NifResult<rs_poker::core::Rank> {
    if state.board.len() != 5 {
        return Err(Error::BadArg);
    }

    let mut hand = state.hands[player_idx];
    for card in &state.board {
        hand.insert(*card);
    }
    Ok(hand.rank())
}

fn is_betting_round(round: Round) -> bool {
    matches!(
        round,
        Round::Preflop | Round::Flop | Round::Turn | Round::River
    )
}

fn deal_hand<R: rand::Rng>(deck: &mut Deck, rng: &mut R) -> NifResult<Hand> {
    let cards = (0..2)
        .map(|_| deck.deal(rng).ok_or(Error::BadArg))
        .collect::<NifResult<Vec<_>>>()?;
    Ok(Hand::new_with_cards(cards))
}

fn snapshot(session: &GameSession) -> NifResult<GameView> {
    let state = session.state.lock().map_err(|_| Error::BadArg)?;
    let outcome = session.outcome.lock().map_err(|_| Error::BadArg)?;
    Ok(snapshot_locked(&state, *outcome))
}

fn snapshot_locked(state: &GameState, outcome: HandOutcome) -> GameView {
    let hero_bet = state.current_round_player_bet(0);
    let (winner, is_tie, reveal_bot_cards) = match outcome {
        HandOutcome::InProgress => (None, false, false),
        HandOutcome::FoldWinner(player_idx) => (Some(player_idx), false, false),
        HandOutcome::ShowdownWinner(player_idx) => (Some(player_idx), false, true),
        HandOutcome::Tie => (None, true, true),
    };

    let best_five = match outcome {
        HandOutcome::ShowdownWinner(player_idx) => best_five_cards(state, player_idx),
        HandOutcome::Tie => best_five_cards(state, 0),
        _ => Vec::new(),
    };

    GameView {
        round: state.round.to_string(),
        acting_player: state.to_act_idx(),
        human_action_enabled: is_betting_round(state.round)
            && state.to_act_idx() == 0
            && !state.is_complete(),
        pot: state.total_pot,
        to_call: (state.current_round_bet() - hero_bet).max(0.0),
        min_raise: if state.current_round_bet() > 0.0 {
            state.current_round_bet() + state.current_round_min_raise()
        } else {
            state.current_round_min_raise()
        },
        max_raise: (state.current_round_player_bet(0) + state.stacks[0])
            .min(state.current_round_player_bet(1) + state.stacks[1])
            - 1.0,
        hero_stack: state.stacks[0],
        bot_stack: state.stacks[1],
        winner,
        is_tie,
        hero_cards: state.hands[0].iter().map(|card| card.to_string()).collect(),
        bot_cards: if reveal_bot_cards {
            state.hands[1].iter().map(|card| card.to_string()).collect()
        } else {
            Vec::new()
        },
        board: state.board.iter().map(|card| card.to_string()).collect(),
        best_five,
    }
}

fn best_five_cards(state: &GameState, player_idx: usize) -> Vec<String> {
    let cards = state.hands[player_idx]
        .iter()
        .chain(state.board.iter().copied())
        .collect::<Vec<_>>();

    if cards.len() < 5 {
        return Vec::new();
    }

    let mut best_rank = None;
    let mut best_five = Vec::new();

    for first in 0..cards.len() - 4 {
        for second in first + 1..cards.len() - 3 {
            for third in second + 1..cards.len() - 2 {
                for fourth in third + 1..cards.len() - 1 {
                    for fifth in fourth + 1..cards.len() {
                        let combo = vec![
                            cards[first],
                            cards[second],
                            cards[third],
                            cards[fourth],
                            cards[fifth],
                        ];
                        let rank = FlatHand::new_with_cards(combo.clone()).rank();

                        if best_rank.is_none_or(|current_rank| rank > current_rank) {
                            best_rank = Some(rank);
                            best_five = combo.iter().map(|card| card.to_string()).collect();
                        }
                    }
                }
            }
        }
    }

    best_five
}

rustler::init!("Elixir.Zoonk.Poker.Native");
