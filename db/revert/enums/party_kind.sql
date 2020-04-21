-- Revert scoutges:enums/party_kind from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TYPE public.party_kind;

COMMIT;

-- vim: expandtab shiftwidth=2
