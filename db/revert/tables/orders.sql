-- Revert scoutges:tables/orders from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE api.orders;

COMMIT;

-- vim: expandtab shiftwidth=2
