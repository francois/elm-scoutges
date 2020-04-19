-- Revert scoutges:acls/tables/customer_addresses from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON public.customer_addresses;
  ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE customer_addresses_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON public.customer_addresses FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
