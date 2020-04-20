-- Revert scoutges:enums/party_type from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TYPE public.party_type;

COMMIT;

-- vim: expandtab shiftwidth=2
