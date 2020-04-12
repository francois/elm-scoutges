-- Deploy scoutges:grants/tables/groups to pg
-- requires: tables/groups

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE public.groups FROM PUBLIC;

  GRANT
      SELECT(name, slug, registered_at)
    , INSERT(name, slug)
    , UPDATE(name, slug)
    , DELETE
  ON TABLE public.groups
  TO authenticated;

  GRANT USAGE ON SEQUENCE groups_id_seq TO authenticated;

  GRANT
      SELECT(pgrole, name, slug, registered_at)
  ON TABLE public.groups
  TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
