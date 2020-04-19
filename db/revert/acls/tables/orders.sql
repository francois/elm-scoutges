-- Revert scoutges:acls/tables/orders from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON public.orders;
  ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE orders_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON public.orders FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
