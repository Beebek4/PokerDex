# Local demo data

Run `mix seed` to add the local PokerDex manager account, PokerDex school, fourteen topic-led Theory modules, the legacy authored tracks, and five street-specific Puzzles packs. Each Puzzles street currently has two short, visual scenarios. The seed is idempotent: rerunning it adds missing records, synchronizes lesson skill levels, and preserves existing lesson content.

The local manager account is `pokerdex-admin` / `admin@pokerdex.example` with the development-only password `Demo1234`. Do not use this account or run seeds in production.

Older development databases may still contain sample schools, demo users, or courses created by the original template. The current seed no longer creates those records, but it does not delete existing database data.
