-- Revert scoutges:tables/customer_addresses from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE public.customer_addresses;

COMMIT;

-- vim: expandtab shiftwidth=2
