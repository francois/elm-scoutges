-- Deploy scoutges:policies/tables/groups to pg
-- requires: tables/groups
-- requires: grants/tables/groups

SET client_min_messages TO 'warning';

BEGIN;

  -- When signing in
  CREATE POLICY anonymous_select
  ON public.groups
  AS PERMISSIVE
  FOR ALL
  TO anonymous
  USING(
    current_user = 'anonymous'
  );

  COMMENT ON POLICY anonymous_select ON public.groups IS 'Used while signing in, when the request is still unauthenticated';

  CREATE POLICY self_select
  ON public.groups
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    current_user = groups.pgrole
  );

  COMMENT ON POLICY self_select ON public.groups IS 'Every member of a group can read their own information';

  CREATE POLICY self_edit
  ON public.groups
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    current_user = groups.pgrole
  );

  COMMENT ON POLICY self_edit ON public.groups IS 'There is a high degree of trust within scouting groups, and as such, we authorize any members of a group to edit the group''s details';

COMMIT;

-- vim: expandtab shiftwidth=2
