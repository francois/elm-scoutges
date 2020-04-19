-- Revert scoutges:sequences/order_nos from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP SEQUENCE public.order_nos;

COMMIT;

-- vim: expandtab shiftwidth=2
