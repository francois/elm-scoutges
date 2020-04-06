-- Revert scoutges:extensions/unaccent from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP EXTENSION unaccent;

COMMIT;

-- vim: expandtab shiftwidth=2
