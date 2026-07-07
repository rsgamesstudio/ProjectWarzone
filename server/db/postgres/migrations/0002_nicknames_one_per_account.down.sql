BEGIN;
ALTER TABLE warzone_nicknames DROP CONSTRAINT IF EXISTS warzone_nicknames_account_id_unique;
COMMIT;
