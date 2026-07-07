-- Phase 8: currency balances + inventory items + equipped loadout
-- slots. Currency lives directly on warzone_accounts (1:1, no need
-- for a join); inventory items and loadout slots are separate tables
-- since an account can own many items but only equip one per slot.

BEGIN;

ALTER TABLE warzone_accounts
    ADD COLUMN credits BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN marks BIGINT NOT NULL DEFAULT 0;

ALTER TABLE warzone_accounts
    ADD CONSTRAINT warzone_accounts_credits_non_negative CHECK (credits >= 0),
    ADD CONSTRAINT warzone_accounts_marks_non_negative CHECK (marks >= 0);

CREATE TABLE warzone_inventory_items (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id     UUID NOT NULL REFERENCES warzone_accounts(id) ON DELETE CASCADE,
    item_id        TEXT NOT NULL,
    acquired_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (account_id, item_id)
);

CREATE INDEX idx_warzone_inventory_items_account_id ON warzone_inventory_items (account_id);

-- One row per (account, slot) — e.g. slot_key = "weapon_skin:assault_rifle"
-- or "character_skin". Deliberately a flexible text key rather than a
-- fixed-column-per-slot design, so new slot types (Phase 10+
-- attachments, future cosmetic categories) don't require a schema
-- migration to add.
CREATE TABLE warzone_loadout_slots (
    account_id     UUID NOT NULL REFERENCES warzone_accounts(id) ON DELETE CASCADE,
    slot_key       TEXT NOT NULL,
    item_id        TEXT NOT NULL,
    equipped_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (account_id, slot_key)
);

COMMIT;
