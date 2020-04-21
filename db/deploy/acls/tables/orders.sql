-- Deploy scoutges:acls/tables/orders to pg
-- requires: tables/orders

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON api.orders FROM PUBLIC;

  GRANT SELECT(name, slug, party_slug, ship_to, bill_to, checkout_on, start_on, end_on, return_on, unavailability_period, created_at, updated_at)
    , INSERT(name, party_slug, ship_to, bill_to, checkout_on, start_on, end_on, return_on)
    , UPDATE(name, party_slug, ship_to, bill_to, checkout_on, start_on, end_on, return_on)
    , DELETE
  ON TABLE api.orders
  TO authenticated;

  GRANT USAGE ON SEQUENCE api.orders_id_seq TO authenticated;

  ALTER TABLE api.orders ENABLE ROW LEVEL SECURITY;

  CREATE POLICY self_crud
  ON api.orders
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING ( orders.pgrole = current_user );

COMMIT;

-- vim: expandtab shiftwidth=2
