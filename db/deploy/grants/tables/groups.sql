-- Deploy scoutges:grants/tables/groups to pg
-- requires: tables/groups

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE public.groups FROM PUBLIC;

  GRANT SELECT, INSERT ON TABLE public.groups TO anonymous;
  GRANT SELECT, UPDATE ON TABLE public.groups TO authenticated;

  GRANT USAGE ON SEQUENCE groups_id_seq TO anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
