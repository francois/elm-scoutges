-- Deploy scoutges:acls/tables/orders to pg
-- requires: tables/orders

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON public.orders FROM PUBLIC;

  GRANT SELECT(name, slug, customer_slug, ship_to, bill_to, checkout_on, start_on, end_on, return_on, created_at, updated_at)
    , INSERT(name, ship_to, bill_to, checkout_on, start_on, end_on, return_on)
    , UPDATE(name, ship_to, bill_to, checkout_on, start_on, end_on, return_on)
    , DELETE
  ON TABLE public.orders
  TO authenticated;

  GRANT USAGE ON SEQUENCE orders_id_seq TO authenticated;

  ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON public.orders
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING ( orders.pgrole = current_user );

COMMIT;

-- vim: expandtab shiftwidth=2
