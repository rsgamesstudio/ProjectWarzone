-- Phase 4: enforce the "one active nickname per account" invariant
-- that server/modules/authentication's provisioning logic relies on
-- (an account has exactly one current nickname row, mutated in place
-- on change rather than appended to a history table). Without this
-- constraint, a race between two concurrent provisioning calls for
-- the same brand-new account could insert two placeholder rows.
--
-- Nickname *history* (if the product wants to show past names later)
-- would be a separate table added when that feature is actually
-- scheduled — not implied by this constraint.

BEGIN;

ALTER TABLE warzone_nicknames
    ADD CONSTRAINT warzone_nicknames_account_id_unique UNIQUE (account_id);

COMMIT;
