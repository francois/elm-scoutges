-- Deploy scoutges:grants/users to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE public.users FROM PUBLIC;

  GRANT
      SELECT(email, password, name, phone, group_name, registered_at)
    , INSERT(email, password, name, phone, group_name)
    , UPDATE(email, password, name, phone)
    , DELETE
  ON public.users TO authenticated;

  GRANT USAGE ON SEQUENCE users_id_seq TO authenticated;

  GRANT
      SELECT(pgrole, email, password, name, phone, group_name, registered_at)
  ON public.users TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
