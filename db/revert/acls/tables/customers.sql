-- Revert scoutges:acls/tables/customers from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON public.customers;
  ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE customers_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON public.customers FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
