-- Deploy scoutges:acls/tables/customers to pg
-- requires: tables/customers

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON public.customers FROM PUBLIC;

  GRANT SELECT(slug, name, external, created_at, updated_at)
    , INSERT(name, external)
    , UPDATE(name, external)
    , DELETE
  ON TABLE public.customers
  TO authenticated;

  GRANT USAGE ON SEQUENCE customers_id_seq TO authenticated;

  ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON public.customers
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING ( customers.pgrole = current_user );

COMMIT;

-- vim: expandtab shiftwidth=2
