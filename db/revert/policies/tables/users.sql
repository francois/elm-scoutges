-- Revert scoutges:policies/users from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY group_crud ON api.users;
  DROP POLICY privileged_sign_in ON api.users;

COMMIT;

-- vim: expandtab shiftwidth=2
