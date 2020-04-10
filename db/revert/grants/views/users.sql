-- Revert scoutges:grants/views/users from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON api.users FROM PUBLIC;

COMMIT;

-- vim: expandtab shiftwidth=2
