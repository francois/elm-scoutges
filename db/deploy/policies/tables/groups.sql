-- Deploy scoutges:policies/tables/groups to pg
-- requires: tables/groups
-- requires: grants/tables/groups

SET client_min_messages TO 'warning';

BEGIN;

  ALTER TABLE api.groups ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON api.groups
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    groups.pgrole = current_user
  );

  COMMENT ON POLICY self_crud ON api.groups IS 'Any member of a group can CRUD all members of the group. This is due to the high degree of trust within scouting groups.';

  CREATE POLICY privileged_sign_in
  ON api.groups
  AS PERMISSIVE
  FOR SELECT
  TO privileged
  USING (true);

  COMMENT ON POLICY privileged_sign_in ON api.groups IS 'Anonymous must have some kind of way to authenticate. Privileged is the user that is allowed to do this operation.';


COMMIT;

-- vim: expandtab shiftwidth=2
