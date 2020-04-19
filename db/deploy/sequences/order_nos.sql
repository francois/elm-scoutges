-- Deploy scoutges:sequences/order_nos to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE SEQUENCE public.order_nos AS integer
  START WITH 10001
  NO CYCLE;

COMMIT;

-- vim: expandtab shiftwidth=2
