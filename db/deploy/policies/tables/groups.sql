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
    current_setting('request.jwt.claim.role', true) = 'anonymous'
  );

  CREATE POLICY self_select
  ON public.groups
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    current_user = groups.pgrole
  );

  CREATE POLICY self_edit
  ON public.groups
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    current_user = groups.pgrole
  );

   COMMENT ON POLICY self_edit ON public.groups IS 'Only allow editing the row that matches "us", the currently logged in user';

COMMIT;

-- vim: expandtab shiftwidth=2
