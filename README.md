# PokerDex

PokerDex is a mobile-friendly Texas Hold’em learning app. It combines short theory lessons with hand-decision practice and saved progress. All chips are fictional; the app is for learning, not gambling.

## Current MVP

- Guest onboarding, with optional account settings.
- Theory lessons that teach Hold’em concepts with clear explanations, examples, and enough text to build understanding.
- Puzzles that foreground the board, table position, and decision, with minimal on-screen text and a concise explanation of why after the answer.
- Saved lesson progress, per-skill practice summaries, and review questions.
- A responsive interface designed for phone browsers as well as desktop.

The current **Just Play** action opens a randomly selected authored lesson from the preflop or flop tracks. It does not yet generate a new random puzzle. Strategy rubrics are draft teaching heuristics and need review by a poker-knowledgeable person before public release.

## Run locally

### Requirements

- Elixir 1.20.5 with Erlang/OTP 29 (other compatible versions may work).
- PostgreSQL 15 or newer, running locally.
- The PostgreSQL connection in `config/dev.exs` currently uses database `zoonk_dev`, username `postgres`, and password `postgres`. Change that local config if your PostgreSQL setup uses different credentials.

### Start the app

```sh
mix setup
mix seed
mix phx.server
```

The local PokerDex school uses the `zoonk.test` hostname. If it is not already mapped to your computer, add `127.0.0.1 zoonk.test` to your hosts file, then open [http://zoonk.test:4000](http://zoonk.test:4000). `mix seed` can be rerun; it adds missing PokerDex demo data and does not overwrite existing lesson content. It does not remove old demo records from an existing database.

The local HTTPS listener uses a development certificate that browsers may not trust. Use the HTTP address above for normal local work; HTTPS on port 4001 is optional.

### Useful commands

```sh
mix test                 # run the test suite
mix seed                 # add missing local demo data
mix phx.server           # start the development server
```

## Data and content

PostgreSQL stores users, lessons, answers, and progress. The authored starter curriculum lives in `lib/content/holdem_curriculum.ex`; `priv/repo/seed/holdem_curriculum.ex` writes it to the local database. The seed process is for development only—do not run it against a production database.

Scenario structure and review requirements are documented in [HOLDEM_CONTENT_CONTRACT.md](HOLDEM_CONTENT_CONTRACT.md). The product roadmap and completed work are in [HOLDEM_TRAINER_PLAN.md](HOLDEM_TRAINER_PLAN.md).

## Project structure

- `lib/content/` — course and lesson data, poker rules, scenarios, learner LiveViews, and progress.
- `lib/accounts/` and `lib/organizations/` — accounts and the school context currently used by the inherited app foundation.
- `priv/repo/migrations/` — database schema changes.
- `priv/repo/seed/` — local PokerDex demo users and curriculum.
- `assets/` — Tailwind styles and browser code.
- `test/` — domain, database, and LiveView tests.

The school and course foundation is still present because the learner routes, course content, and local app setup depend on it. The generic sample schools and sample courses from the original template are not part of the PokerDex seed data.

## Next product steps

1. Review the draft strategic answers with a poker-knowledgeable reviewer.
2. Give Theory and Puzzles distinct experiences: teach concepts in sequence in Theory; keep Puzzles visual and focused on reading board texture and position, then explain the reasoning after the choice. They may reuse the current authored scenario pool at first.
3. Add a constrained, reproducible puzzle generator only after its templates and rule checks are reviewed.
4. Check accessibility, phone layouts, and data handling before inviting external learners.

## License

This repository retains its [GNU AGPL v3 license](LICENSE). Review the license before distributing or hosting a modified version.
