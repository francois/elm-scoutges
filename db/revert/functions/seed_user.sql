-- Revert scoutges-test:functions/seed_user from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION api.seed_user(text, text, text, text, text);

COMMIT;

-- vim: expandtab shiftwidth=2
