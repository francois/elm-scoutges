-- Deploy scoutges:policies/users to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  ALTER TABLE api.users ENABLE ROW LEVEL SECURITY;

  CREATE POLICY group_crud
  ON api.users
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    users.pgrole = current_user
  );

  COMMENT ON POLICY group_crud ON api.users IS 'Every user can read all users of their group';

  CREATE POLICY privileged_sign_in
  ON api.users
  AS PERMISSIVE
  FOR SELECT
  TO privileged
  USING (true);

  COMMENT ON POLICY privileged_sign_in ON api.users IS 'Anonymous must have some kind of way to authenticate. Privileged is the user that is allowed to do this operation.';

COMMIT;

-- vim: expandtab shiftwidth=2
