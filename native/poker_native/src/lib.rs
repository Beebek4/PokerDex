use rs_poker::arena::game_state::{GameState, Round, RoundData};
use rs_poker::arena::{Agent, GameStateBuilder, HoldemSimulationBuilder, agent::CallingAgent};
use rs_poker::core::{Deck, FlatHand, Hand, PlayerBitSet, Rankable};
use rustler::{Error, NifResult, Resource, ResourceArc};
use std::sync::Mutex;

struct GameSession {
    state: Mutex<GameState>,
    deck: Mutex<Deck>,
    outcome: Mutex<HandOutcome>,
    small_blind_idx: usize,
    big_blind_idx: usize,
}

#[derive(Clone)]
enum HandOutcome {
    InProgress,
    FoldWinner(usize),
    ShowdownWinners(Vec<usize>),
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
    winners: Vec<usize>,
    player_best_fives: Vec<Vec<String>>,
    hero_cards: Vec<String>,
    bot_cards: Vec<String>,
    bot_private_cards: Vec<String>,
    player_stacks: Vec<f32>,
    player_hole_cards: Vec<Vec<String>>,
    player_contributions: Vec<f32>,
    player_folded: Vec<bool>,
    player_all_in: Vec<bool>,
    dealer_idx: usize,
    small_blind_idx: usize,
    big_blind_idx: usize,
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
    start_session(vec![hero_total, bot_total], 0, 5.0, 10.0)
}

#[rustler::nif]
fn start_play_hand(
    hero_total: f32,
    bot_total: f32,
    small_blind: f32,
    big_blind: f32,
) -> NifResult<(ResourceArc<GameSession>, GameView)> {
    start_session(vec![hero_total, bot_total], 0, small_blind, big_blind)
}

#[rustler::nif]
fn start_play_hand_with_button(
    hero_total: f32,
    bot_total: f32,
    small_blind: f32,
    big_blind: f32,
    dealer_idx: usize,
) -> NifResult<(ResourceArc<GameSession>, GameView)> {
    start_session(
        vec![hero_total, bot_total],
        dealer_idx,
        small_blind,
        big_blind,
    )
}

#[rustler::nif]
fn start_tournament_hand(
    stacks: Vec<f32>,
    dealer_idx: usize,
    small_blind: f32,
    big_blind: f32,
) -> NifResult<(ResourceArc<GameSession>, GameView)> {
    start_session(stacks, dealer_idx, small_blind, big_blind)
}

fn start_session(
    total_stacks: Vec<f32>,
    requested_dealer_idx: usize,
    small_blind: f32,
    big_blind: f32,
) -> NifResult<(ResourceArc<GameSession>, GameView)> {
    let num_players = total_stacks.len();

    if !(2..=6).contains(&num_players)
        || total_stacks
            .iter()
            .any(|stack| !stack.is_finite() || *stack < 0.0)
        || total_stacks.iter().filter(|stack| **stack > 0.0).count() < 2
        || !small_blind.is_finite()
        || !big_blind.is_finite()
        || small_blind <= 0.0
        || big_blind < small_blind
        || requested_dealer_idx >= num_players
    {
        return Err(Error::BadArg);
    }

    let dealer_idx = if total_stacks[requested_dealer_idx] > 0.0 {
        requested_dealer_idx
    } else {
        next_player_with_chips(requested_dealer_idx, &total_stacks).ok_or(Error::BadArg)?
    };
    let live_player_count = total_stacks.iter().filter(|stack| **stack > 0.0).count();
    let small_blind_idx = if live_player_count == 2 {
        dealer_idx
    } else {
        next_player_with_chips(dealer_idx, &total_stacks).ok_or(Error::BadArg)?
    };
    let big_blind_idx =
        next_player_with_chips(small_blind_idx, &total_stacks).ok_or(Error::BadArg)?;

    let mut deck = Deck::default();
    let mut rng = rand::rng();
    let hands = (0..num_players)
        .map(|_| deal_hand(&mut deck, &mut rng))
        .collect::<NifResult<Vec<_>>>()?;

    let mut contributions = vec![0.0; num_players];
    let mut stacks = total_stacks.clone();
    let sb_amount = stacks[small_blind_idx].min(small_blind);
    let bb_amount = stacks[big_blind_idx].min(big_blind);
    stacks[small_blind_idx] -= sb_amount;
    stacks[big_blind_idx] -= bb_amount;
    contributions[small_blind_idx] = sb_amount;
    contributions[big_blind_idx] = bb_amount;

    let mut able_to_act = PlayerBitSet::default();
    for (idx, stack) in stacks.iter().enumerate() {
        if *stack > 0.0 {
            able_to_act.enable(idx);
        }
    }

    let first_to_act = if hand_live_players_count_from(&stacks, &contributions) == 2 {
        if stacks[dealer_idx] > 0.0 {
            dealer_idx
        } else {
            next_player_with_chips(dealer_idx, &stacks).ok_or(Error::BadArg)?
        }
    } else {
        next_player_with_chips(big_blind_idx, &stacks)
            .or_else(|| stacks.iter().position(|stack| *stack > 0.0))
            .ok_or(Error::BadArg)?
    };

    let mut round_data =
        RoundData::new_with_bets(big_blind, able_to_act, first_to_act, contributions.clone());
    round_data.total_raise_count = 0;
    round_data.total_bet_count = 2;
    round_data.forced_bet_count = 2;
    let mut state = GameStateBuilder::new()
        .stacks(stacks)
        .blinds(big_blind, small_blind)
        .dealer_idx(dealer_idx)
        .round(Round::Preflop)
        .hands(hands)
        .player_bet(contributions)
        .round_data(round_data)
        .build()
        .map_err(|_| Error::BadArg)?;

    // The crate's builder marks zero-stack blind posters as all-in, but does
    // not remove them from `player_active`; do so before the next street is
    // initialized so an all-in seat cannot be asked to act again.
    for idx in 0..num_players {
        if state.stacks[idx] <= 0.0 {
            state.player_active.disable(idx);
            if state.player_bet[idx] > 0.0 {
                state.player_all_in.enable(idx);
            }
        }
    }

    let session = ResourceArc::new(GameSession {
        state: Mutex::new(state),
        deck: Mutex::new(deck),
        outcome: Mutex::new(HandOutcome::InProgress),
        small_blind_idx,
        big_blind_idx,
    });
    let view = snapshot(&session)?;

    Ok((session, view))
}

fn next_player_with_chips(after_idx: usize, stacks: &[f32]) -> Option<usize> {
    (1..=stacks.len())
        .map(|distance| (after_idx + distance) % stacks.len())
        .find(|idx| stacks[*idx] > 0.0)
}

fn hand_live_players_count_from(stacks: &[f32], contributions: &[f32]) -> usize {
    stacks
        .iter()
        .zip(contributions)
        .filter(|(stack, contribution)| **stack > 0.0 || **contribution > 0.0)
        .count()
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

    if !is_current_action(&state, 0) {
        return Err(Error::BadArg);
    }

    let mut outcome = session.outcome.lock().map_err(|_| Error::BadArg)?;
    apply_player_action(&mut state, &mut outcome, 0, &action, amount)?;

    let mut deck = session.deck.lock().map_err(|_| Error::BadArg)?;
    advance_until_human_turn(&mut state, &mut deck, &mut outcome)?;
    Ok(snapshot_locked(
        &state,
        &outcome,
        session.small_blind_idx,
        session.big_blind_idx,
    ))
}

/// Apply one player's action and stop at the next decision point. Elixir owns
/// bot-policy orchestration; this NIF remains responsible for poker mechanics.
#[rustler::nif]
fn player_action(
    session: ResourceArc<GameSession>,
    actor: usize,
    action: String,
    amount: f32,
) -> NifResult<GameView> {
    let mut state = session.state.lock().map_err(|_| Error::BadArg)?;
    let mut deck = session.deck.lock().map_err(|_| Error::BadArg)?;
    let mut outcome = session.outcome.lock().map_err(|_| Error::BadArg)?;

    if !is_current_action(&state, actor) {
        return Err(Error::BadArg);
    }

    apply_player_action(&mut state, &mut outcome, actor, &action, amount)?;

    advance_to_next_action(&mut state, &mut deck, &mut outcome)?;
    Ok(snapshot_locked(
        &state,
        &outcome,
        session.small_blind_idx,
        session.big_blind_idx,
    ))
}

fn is_current_action(state: &GameState, actor: usize) -> bool {
    is_betting_round(state.round)
        && actor < state.num_players
        && state.to_act_idx() == actor
        && state.round_data.needs_action.get(actor)
        && state.player_active.get(actor)
        && state.round != Round::Complete
}

fn apply_player_action(
    state: &mut GameState,
    outcome: &mut HandOutcome,
    actor: usize,
    action: &str,
    amount: f32,
) -> NifResult<()> {
    match action {
        "fold" => {
            state.fold();
            if hand_live_players(state).count() == 1 {
                let winner = hand_live_players(state)
                    .ones()
                    .next()
                    .ok_or(Error::BadArg)?;
                state.award(winner, state.total_pot);
                state.complete();
                *outcome = HandOutcome::FoldWinner(winner);
            }
        }
        "call" => {
            let call_amount = state.current_round_bet();
            state
                .do_bet(call_amount, false)
                .map_err(|_| Error::BadArg)?;
        }
        "check" => {
            if state.current_round_player_bet(actor) < state.current_round_bet() {
                return Err(Error::BadArg);
            }
            let current_bet = state.current_round_bet();
            state
                .do_bet(current_bet, false)
                .map_err(|_| Error::BadArg)?;
        }
        "raise" => {
            if !amount.is_finite() || amount <= state.current_round_player_bet(actor) {
                return Err(Error::BadArg);
            }
            state.do_bet(amount, false).map_err(|_| Error::BadArg)?;
        }
        _ => return Err(Error::BadArg),
    }

    Ok(())
}

fn advance_to_next_action(
    state: &mut GameState,
    deck: &mut Deck,
    outcome: &mut HandOutcome,
) -> NifResult<()> {
    for _ in 0..8 {
        if hand_is_over(state) {
            return Ok(());
        }

        if should_run_out_after_all_in(state) {
            return run_out_after_all_in(state, deck, outcome);
        }

        if state.current_round_num_active_players() > 0 {
            return Ok(());
        }

        state.advance_round();
        match state.round {
            Round::DealFlop => {
                deal_community_cards(state, deck, 3)?;
                state.advance_round();
                set_short_table_postflop_actor(state);
            }
            Round::DealTurn | Round::DealRiver => {
                deal_community_cards(state, deck, 1)?;
                state.advance_round();
                set_short_table_postflop_actor(state);
            }
            Round::Showdown => {
                settle_showdown(state, outcome)?;
                return Ok(());
            }
            Round::Complete => return Ok(()),
            _ => {}
        }
    }

    Err(Error::BadArg)
}

fn should_run_out_after_all_in(state: &GameState) -> bool {
    if state.player_all_in.count() == 0 || state.player_active.count() > 1 {
        return false;
    }

    let current_bet = state.current_round_bet();
    (0..state.num_players)
        .filter(|idx| state.player_active.get(*idx))
        .all(|idx| state.current_round_player_bet(idx) + 0.0001 >= current_bet)
}

fn run_out_after_all_in(
    state: &mut GameState,
    deck: &mut Deck,
    outcome: &mut HandOutcome,
) -> NifResult<()> {
    for _ in 0..4 {
        if hand_is_over(state) {
            return Ok(());
        }

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
    }

    Err(Error::BadArg)
}

fn advance_until_human_turn(
    state: &mut GameState,
    deck: &mut Deck,
    outcome: &mut HandOutcome,
) -> NifResult<()> {
    for _ in 0..40 {
        advance_to_next_action(state, deck, outcome)?;
        if hand_is_over(state) || state.to_act_idx() == 0 {
            return Ok(());
        }

        let actor = state.to_act_idx();
        if !state.player_active.get(actor) {
            return Err(Error::BadArg);
        }
        let call_amount = state.current_round_bet();
        state
            .do_bet(call_amount, false)
            .map_err(|_| Error::BadArg)?;
    }

    Err(Error::BadArg)
}

fn hand_live_players(state: &GameState) -> PlayerBitSet {
    state.player_active | state.player_all_in
}

fn hand_is_over(state: &GameState) -> bool {
    state.round == Round::Complete || hand_live_players(state).count() <= 1
}

fn set_short_table_postflop_actor(state: &mut GameState) {
    if hand_live_players(state).count() == 2 && state.player_active.count() > 0 {
        let first_to_act = (0..state.num_players)
            .map(|distance| (state.dealer_idx + distance) % state.num_players)
            .find(|idx| state.player_active.get(*idx));
        if let Some(idx) = first_to_act {
            state.round_data.to_act_idx = idx;
        }
    }
}

fn deal_community_cards(state: &mut GameState, deck: &mut Deck, count: usize) -> NifResult<()> {
    let mut rng = rand::rng();
    for _ in 0..count {
        state.board.push(deck.deal(&mut rng).ok_or(Error::BadArg)?);
    }
    Ok(())
}

fn settle_showdown(state: &mut GameState, outcome: &mut HandOutcome) -> NifResult<()> {
    let eligible = hand_live_players(state);
    let mut levels = state
        .player_bet
        .iter()
        .copied()
        .filter(|contribution| *contribution > 0.0)
        .collect::<Vec<_>>();
    levels.sort_by(f32::total_cmp);
    levels.dedup_by(|left, right| (*left - *right).abs() < 0.0001);

    let mut previous_level = 0.0;
    let mut main_pot_winners = Vec::new();

    for level in levels {
        let contributors = state
            .player_bet
            .iter()
            .filter(|bet| **bet + 0.0001 >= level)
            .count();
        let pot = (level - previous_level) * contributors as f32;
        previous_level = level;

        let eligible_players = (0..state.num_players)
            .filter(|idx| state.player_bet[*idx] + 0.0001 >= level && eligible.get(*idx))
            .collect::<Vec<_>>();
        if eligible_players.is_empty() || pot <= 0.0 {
            continue;
        }

        let mut best_rank = None;
        let mut winners = Vec::new();
        for player_idx in eligible_players {
            let rank = rank_player_hand(state, player_idx)?;
            match best_rank.map(|current| rank.cmp(&current)) {
                None | Some(std::cmp::Ordering::Greater) => {
                    best_rank = Some(rank);
                    winners.clear();
                    winners.push(player_idx);
                }
                Some(std::cmp::Ordering::Equal) => winners.push(player_idx),
                Some(std::cmp::Ordering::Less) => {}
            }
        }

        if main_pot_winners.is_empty() {
            main_pot_winners = winners.clone();
        }
        let share = pot / winners.len() as f32;
        for winner in winners {
            state.award(winner, share);
        }
    }

    if main_pot_winners.is_empty() {
        return Err(Error::BadArg);
    }

    *outcome = HandOutcome::ShowdownWinners(main_pot_winners);
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
    Ok(snapshot_locked(
        &state,
        &outcome,
        session.small_blind_idx,
        session.big_blind_idx,
    ))
}

fn snapshot_locked(
    state: &GameState,
    outcome: &HandOutcome,
    small_blind_idx: usize,
    big_blind_idx: usize,
) -> GameView {
    let acting_player = state.to_act_idx().min(state.num_players.saturating_sub(1));
    let acting_bet = state.current_round_player_bet(acting_player);
    let (winners, reveal_cards) = match outcome {
        HandOutcome::InProgress => (Vec::new(), false),
        HandOutcome::FoldWinner(player_idx) => (vec![*player_idx], false),
        HandOutcome::ShowdownWinners(players) => (players.clone(), true),
    };
    let winner = winners.first().copied();

    let player_best_fives = (0..state.num_players)
        .map(|idx| {
            if reveal_cards && winners.contains(&idx) {
                best_five_cards(state, idx)
            } else {
                Vec::new()
            }
        })
        .collect::<Vec<_>>();
    let best_five = player_best_fives.first().cloned().unwrap_or_default();
    let other_stack = state
        .stacks
        .iter()
        .enumerate()
        .filter(|(idx, _)| *idx != acting_player)
        .map(|(_, stack)| *stack)
        .max_by(f32::total_cmp)
        .unwrap_or(0.0);

    GameView {
        round: state.round.to_string(),
        acting_player,
        human_action_enabled: is_current_action(state, 0),
        pot: state.total_pot,
        to_call: (state.current_round_bet() - acting_bet).max(0.0),
        min_raise: if state.current_round_bet() > 0.0 {
            state.current_round_bet() + state.current_round_min_raise()
        } else {
            state.current_round_min_raise()
        },
        max_raise: acting_bet + state.stacks[acting_player],
        hero_stack: state.stacks.first().copied().unwrap_or(0.0),
        bot_stack: if acting_player == 0 {
            other_stack
        } else {
            state.stacks[acting_player]
        },
        winner,
        is_tie: winners.len() > 1,
        winners: winners.clone(),
        player_best_fives,
        hero_cards: state.hands[0].iter().map(|card| card.to_string()).collect(),
        bot_cards: if reveal_cards && state.hands.len() > 1 {
            state.hands[1].iter().map(|card| card.to_string()).collect()
        } else {
            Vec::new()
        },
        bot_private_cards: if acting_player > 0 {
            state.hands[acting_player]
                .iter()
                .map(|card| card.to_string())
                .collect()
        } else if state.hands.len() > 1 {
            state.hands[1].iter().map(|card| card.to_string()).collect()
        } else {
            Vec::new()
        },
        player_stacks: state.stacks.iter().copied().collect(),
        player_hole_cards: state
            .hands
            .iter()
            .map(|hand| {
                if reveal_cards {
                    hand.iter().map(|card| card.to_string()).collect()
                } else {
                    Vec::new()
                }
            })
            .collect(),
        player_contributions: state.player_bet.iter().copied().collect(),
        player_folded: (0..state.num_players)
            .map(|idx| !state.player_active.get(idx) && !state.player_all_in.get(idx))
            .collect(),
        player_all_in: (0..state.num_players)
            .map(|idx| state.player_all_in.get(idx))
            .collect(),
        dealer_idx: state.dealer_idx,
        small_blind_idx,
        big_blind_idx,
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
