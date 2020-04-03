-- Revert scoutges:schemas/api from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP SCHEMA api CASCADE;

COMMIT;

-- vim: expandtab shiftwidth=2
