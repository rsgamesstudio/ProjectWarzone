BEGIN;
DROP TABLE IF EXISTS warzone_loadout_slots;
DROP TABLE IF EXISTS warzone_inventory_items;
ALTER TABLE warzone_accounts
    DROP CONSTRAINT IF EXISTS warzone_accounts_credits_non_negative,
    DROP CONSTRAINT IF EXISTS warzone_accounts_marks_non_negative,
    DROP COLUMN IF EXISTS credits,
    DROP COLUMN IF EXISTS marks;
COMMIT;
