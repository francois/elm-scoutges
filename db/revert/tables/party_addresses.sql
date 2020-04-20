-- Revert scoutges:tables/party_addresses from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE public.party_addresses;

COMMIT;

-- vim: expandtab shiftwidth=2
