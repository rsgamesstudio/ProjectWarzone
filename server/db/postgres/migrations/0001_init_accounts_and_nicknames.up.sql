-- Phase 2/4 / ADR-0002 + ADR-0003: foundational tables for the
-- account-extension and permanent nickname system. This runs against
-- the SAME Postgres database Nakama itself uses (see ADR-0003) — the
-- `warzone_` prefix keeps these tables visually and structurally
-- distinct from Nakama's own internal tables (users, storage, etc.)
-- living in that same database.
--
-- `warzone_accounts.nakama_user_id` links back to Nakama's own `users`
-- table by ID. It is NOT declared as a foreign key even though both
-- tables are now in the same database: Nakama owns and migrates its
-- own schema independently, and we deliberately avoid taking a hard
-- FK dependency on a table we don't control the lifecycle of.
-- Referential integrity for that link is enforced application-side in
-- server/modules/authentication.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS warzone_accounts (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nakama_user_id     UUID NOT NULL UNIQUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Case-insensitive uniqueness on nickname is enforced via a functional
-- unique index on lower(nickname), not a UNIQUE column constraint,
-- so "Sukesh" and "sukesh" cannot both be claimed.
CREATE TABLE IF NOT EXISTS warzone_nicknames (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id         UUID NOT NULL REFERENCES warzone_accounts(id) ON DELETE CASCADE,
    nickname           TEXT NOT NULL,
    is_placeholder     BOOLEAN NOT NULL DEFAULT true,
    claimed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_changed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    change_count       INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT nickname_length CHECK (char_length(nickname) BETWEEN 3 AND 20),
    CONSTRAINT nickname_charset CHECK (nickname ~ '^[A-Za-z0-9_]+$')
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_warzone_nicknames_lower_unique
    ON warzone_nicknames (lower(nickname));

CREATE INDEX IF NOT EXISTS idx_warzone_nicknames_account_id
    ON warzone_nicknames (account_id);

COMMIT;
