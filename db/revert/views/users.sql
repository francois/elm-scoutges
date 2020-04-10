-- Revert scoutges:views/users from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP VIEW api.users;

COMMIT;

-- vim: expandtab shiftwidth=2
