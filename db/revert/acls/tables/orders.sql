-- Revert scoutges:acls/tables/orders from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON api.orders;
  ALTER TABLE api.orders DISABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE api.orders_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON api.orders FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
