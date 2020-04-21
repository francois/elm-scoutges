-- Revert scoutges:acls/tables/parties from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON api.parties;
  ALTER TABLE api.parties DISABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE api.parties_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON api.parties FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
