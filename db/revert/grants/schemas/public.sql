-- Revert scoutges:grants/schemas/public from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON SCHEMA public FROM PUBLIC;

COMMIT;

-- vim: expandtab shiftwidth=2
