-- Revert scoutges-test:extensions/pgtap from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP EXTENSION pgtap;

COMMIT;

-- vim: expandtab shiftwidth=2
