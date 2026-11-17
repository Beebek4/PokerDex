# Local demo data

Run `mix seed` to add the local PokerDex manager account, PokerDex school, and three authored Hold’em curriculum tracks. The seed is idempotent: rerunning it adds missing records and preserves existing lesson content.

The local manager account is `pokerdex-admin` / `admin@pokerdex.example` with the development-only password `Demo1234`. Do not use this account or run seeds in production.

Older development databases may still contain sample schools, demo users, or courses created by the original template. The current seed no longer creates those records, but it does not delete existing database data.
