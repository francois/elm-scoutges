-- Revert scoutges:tables/customers from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE public.customers;

COMMIT;

-- vim: expandtab shiftwidth=2
