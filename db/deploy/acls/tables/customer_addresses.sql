-- Deploy scoutges:acls/tables/customer_addresses to pg
-- requires: tables/customer_addresses

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON public.customer_addresses FROM PUBLIC;

  GRANT SELECT(customer_slug, name, address, created_at, updated_at)
    , INSERT(customer_slug, name, address)
    , UPDATE(name, address)
    , DELETE
  ON TABLE public.customer_addresses
  TO authenticated;

  GRANT USAGE ON SEQUENCE customer_addresses_id_seq TO authenticated;

  ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON public.customer_addresses
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING ( customer_addresses.pgrole = current_user );

COMMIT;

-- vim: expandtab shiftwidth=2
