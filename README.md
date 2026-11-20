# PokerDex

PokerDex is a mobile-friendly Texas Hold’em learning app. It combines short theory lessons with hand-decision practice and saved progress. All chips are fictional; the app is for learning, not gambling.

## Current MVP

- Guest onboarding, with optional account settings.
- A vertical Play journey map with a Home location for Teddy, Grandpa, Mum, Brother, Sister, and Dad, followed by the Garage Tournament. Campaign chips and Respect unlock matches. The tournament uses the multiway poker engine and rotates the button and blinds.
- A topic-led Theory path from poker foundations and decision-making through preflop, equity, board reading, betting, responses, and later-street planning. Beginner lessons and a first stack-depth lesson are available; other intermediate and advanced topics are shown as planned modules.
- Puzzles grouped by Preflop, Flop, Turn, River, and Showdown. Each street has concise, authored visual puzzles. Choose a street to start a random hand, with an optional skill-level filter.
- Saved lesson progress, per-skill practice summaries, and review questions.
- A responsive interface designed for phone browsers as well as desktop.

Home puts Play first, with lessons and Theory secondary. The Home journey uses one shared opponent catalogue and one rule-based policy parameterized by profiles for Teddy, Grandpa, Mum, Brother, Sister, and Dad. Teddy, Grandpa, and Mum use Easy; Brother and Sister use Standard; Dad uses Hard. Heads-up bots wait 0–3 seconds before acting, while tournament bots wait 0–2 seconds; profile and action tendencies shape the delay. Completed matches save fictional-chip balances, Respect, and opponent records in PostgreSQL. Teddy's free warm-up restores a 100-chip minimum if the player runs out; an opponent grants Respect only for the first win. The multiway Garage Tournament is implemented, including rotating positions and blinds. Hand state is temporary: returning to the map refunds an unfinished match; refreshing shows a recovery prompt and leaves the entry reserved until the player chooses to refund it. Durable hand resume and poker-reviewed strategy remain future work. See [HOLDEM_BOT_ROSTER.md](HOLDEM_BOT_ROSTER.md) for bot intent and current limitations. **Just Play** selects an authored puzzle across the five streets; it does not generate new puzzles yet. Strategy rubrics are draft teaching heuristics and need review by a poker-knowledgeable person before public release.

## Run locally

### Requirements

- Elixir 1.20.5 with Erlang/OTP 29 (other compatible versions may work).
- Rust 1.100.0 through Rustup for the native poker engine (Rust 2024 edition). The repository pins this in `rust-toolchain.toml`.
- PostgreSQL 15 or newer, running locally.
- The PostgreSQL connection in `config/dev.exs` currently uses database `zoonk_dev`, username `postgres`, and password `postgres`. Change that local config if your PostgreSQL setup uses different credentials.

### Start the app

```sh
rustup toolchain install 1.100.0
export PATH="$(rustup run 1.100.0 rustc --print sysroot)/bin:$PATH"
rustc --version
cargo --version
mix setup
mix seed
mix phx.server
```

The local PokerDex school uses the `zoonk.test` hostname. If it is not already mapped to your computer, add `127.0.0.1 zoonk.test` to your hosts file, then open [http://zoonk.test:4000](http://zoonk.test:4000). `mix seed` can be rerun; it adds missing PokerDex demo data and does not overwrite existing lesson content. It does not remove old demo records from an existing database.

When updating an existing checkout, apply pending database changes with `mix ecto.migrate` before starting the app. New installations get the current schema from `mix setup`.

The local HTTPS listener uses a development certificate that browsers may not trust. Use the HTTP address above for normal local work; HTTPS on port 4001 is optional.

### Useful commands

```sh
mix test                 # run the test suite
mix seed                 # add missing local demo data
mix phx.server           # start the development server
```

## Data and content

PostgreSQL stores users, lessons, answers, poker campaign balances, and match records. Authored puzzle content lives in `lib/content/holdem_curriculum.ex`; Theory topics and lessons live in `lib/content/holdem_theory_curriculum.ex`. `priv/repo/seed/holdem_curriculum.ex` writes both to the local database. The seed process is for development only—do not run it against a production database.

Scenario structure and review requirements are documented in [HOLDEM_CONTENT_CONTRACT.md](HOLDEM_CONTENT_CONTRACT.md). The product roadmap and completed work are in [HOLDEM_TRAINER_PLAN.md](HOLDEM_TRAINER_PLAN.md).

The topic-led Theory page follows the progression in [HOLDEM_THEORY_CURRICULUM.md](HOLDEM_THEORY_CURRICULUM.md). Beginner lessons are authored for the first concepts, while later modules remain visible as planned topics.

## Project structure

- `lib/content/` — course and lesson data, puzzle rules and scenarios, learner LiveViews, and learning progress.
- `lib/poker/` — opponent catalogue, shared bot policy and styles, campaign context, and campaign/match schemas.
- `lib/accounts/` and `lib/organizations/` — accounts and the school context currently used by the inherited app foundation.
- `priv/repo/migrations/` — database schema changes.
- `priv/repo/seed/` — local PokerDex demo users and curriculum.
- `assets/` — Tailwind styles and browser code.
- `native/poker_native/` — Rustler NIF using `rs-poker` for the Play table prototype.
- `test/` — domain, database, and LiveView tests.

The school and course foundation is still present because the learner routes, course content, and local app setup depend on it. The generic sample schools and sample courses from the original template are not part of the PokerDex seed data.

## Next product steps

1. Improve and validate the baseline bot profiles and multiway tournament behavior with a poker-knowledgeable reviewer.
2. Review the draft strategic puzzle answers with a poker-knowledgeable reviewer.
3. Keep Puzzles visual and brief before the decision, then explain the reasoning after the choice. Expand the authored street sets as their answer keys are reviewed.
4. Fill in the remaining beginner Theory topics, then add the intermediate and advanced modules from the curriculum note.
5. Add a constrained, reproducible puzzle generator only after its templates and rule checks are reviewed.
6. Check accessibility, phone layouts, and data handling before inviting external learners.

## License

This repository retains its [GNU AGPL v3 license](LICENSE). Review the license before distributing or hosting a modified version.
