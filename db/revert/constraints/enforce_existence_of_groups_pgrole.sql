-- Revert scoutges:constraints/enforce_existence_of_users_pguser from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TRIGGER IF EXISTS check_role_exists ON api.users;

COMMIT;

-- vim: expandtab shiftwidth=2
