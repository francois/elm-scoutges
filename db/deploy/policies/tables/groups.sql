-- Deploy scoutges:policies/tables/groups to pg
-- requires: tables/groups
-- requires: grants/tables/groups

SET client_min_messages TO 'warning';

BEGIN;

  CREATE POLICY self_crud
  ON public.groups
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    groups.pgrole = current_user
  );

  COMMENT ON POLICY self_crud ON public.groups IS 'Any member of a group can CRUD all members of the group. This is due to the high degree of trust within scouting groups.';

  CREATE POLICY anon_sign_in
  ON public.groups
  AS PERMISSIVE
  FOR SELECT
  TO anonymous
  USING (true);

  COMMENT ON POLICY anon_sign_in ON public.groups IS 'Anonymous must be able to find their record in order to sign in';


COMMIT;

-- vim: expandtab shiftwidth=2
