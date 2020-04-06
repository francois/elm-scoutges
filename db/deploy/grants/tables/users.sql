-- Deploy scoutges:grants/users to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE public.users FROM PUBLIC;

  GRANT
      -- When signing in
      SELECT(email, password, group_name)
      -- When registering
    , INSERT(email, password, name, phone, group_name, pgrole)
  ON public.users TO anonymous;

  GRANT SELECT(email, password, name, phone, group_name, pgrole)
  ON public.users TO authenticated;

  GRANT USAGE ON SEQUENCE users_id_seq TO anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
