-- Deploy scoutges:acls/tables/parties to pg
-- requires: tables/parties

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON public.parties FROM PUBLIC;

  GRANT SELECT(slug, name, type, created_at, updated_at)
    , INSERT(name, type)
    , UPDATE(name, type)
    , DELETE
  ON TABLE public.parties
  TO authenticated;

  GRANT USAGE ON SEQUENCE parties_id_seq TO authenticated;

  ALTER TABLE public.parties ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON public.parties
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING ( parties.pgrole = current_user );

COMMIT;

-- vim: expandtab shiftwidth=2
