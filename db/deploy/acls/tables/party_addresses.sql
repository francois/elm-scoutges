-- Deploy scoutges:acls/tables/party_addresses to pg
-- requires: tables/party_addresses

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON api.party_addresses FROM PUBLIC;

  GRANT SELECT(party_slug, name, address, created_at, updated_at)
    , INSERT(party_slug, name, address, pgrole)
    , UPDATE(name, address)
    , DELETE
  ON TABLE api.party_addresses
  TO authenticated;

  GRANT USAGE ON SEQUENCE api.party_addresses_id_seq TO authenticated;

  ALTER TABLE api.party_addresses ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON api.party_addresses
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING ( party_addresses.pgrole = current_user );

COMMIT;

-- vim: expandtab shiftwidth=2
