-- Revert scoutges:extensions/citext from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP EXTENSION IF EXISTS "citext";

COMMIT;

-- vim: expandtab shiftwidth=2
