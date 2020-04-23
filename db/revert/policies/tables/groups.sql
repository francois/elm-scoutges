-- Revert scoutges:policies/tables/groups from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY privileged_sign_in ON api.groups;
  DROP POLICY self_crud ON api.groups;

COMMIT;

-- vim: expandtab shiftwidth=2
