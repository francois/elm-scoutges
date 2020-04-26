-- Deploy scoutges:acls/tables/parties to pg
-- requires: tables/parties

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON api.parties FROM PUBLIC;

  GRANT SELECT(slug, name, kind, created_at, updated_at)
    , INSERT(name, kind, pgrole)
    , UPDATE(name, kind)
    , DELETE
  ON TABLE api.parties
  TO authenticated;

  GRANT USAGE ON SEQUENCE api.parties_id_seq TO authenticated;

  ALTER TABLE api.parties ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON api.parties
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING ( parties.pgrole = current_user );

COMMIT;

-- vim: expandtab shiftwidth=2
