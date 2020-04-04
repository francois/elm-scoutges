-- Revert scoutges:grants/schemas/api from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE USAGE ON SCHEMA api FROM anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
