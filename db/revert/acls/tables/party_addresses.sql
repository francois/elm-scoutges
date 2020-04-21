-- Revert scoutges:acls/tables/party_addresses from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON api.party_addresses;
  ALTER TABLE api.party_addresses ENABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE api.party_addresses_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON api.party_addresses FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
