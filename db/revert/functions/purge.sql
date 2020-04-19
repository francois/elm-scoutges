-- Revert scoutges-test:functions/purge from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION api.purge();

COMMIT;

-- vim: expandtab shiftwidth=2
