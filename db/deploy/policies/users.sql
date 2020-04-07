-- Deploy scoutges:policies/users to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  CREATE POLICY anonymous_select
  ON public.users
  AS PERMISSIVE
  FOR ALL
  TO anonymous
  USING(
    current_user = 'anonymous'
  );

  COMMENT ON POLICY anonymous_select ON public.users IS 'Used while signing in, when the request is still unauthenticated';

  CREATE POLICY self_select
  ON public.users
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    current_user = users.pgrole
  );

  COMMENT ON POLICY self_select ON public.users IS 'Every user can read all users of their group';

  CREATE POLICY self_edit
  ON public.users
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
        current_user = users.pgrole
    AND current_setting('request.jwt.claim.email', true) = users.email
  );

  COMMENT ON POLICY self_edit ON public.users IS 'Every user can edit their own details';

COMMIT;

-- vim: expandtab shiftwidth=2
