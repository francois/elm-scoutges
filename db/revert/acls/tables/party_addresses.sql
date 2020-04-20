-- Revert scoutges:acls/tables/party_addresses from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON public.party_addresses;
  ALTER TABLE public.party_addresses ENABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE party_addresses_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON public.party_addresses FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
