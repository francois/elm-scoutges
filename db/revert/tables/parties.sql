-- Revert scoutges:tables/parties from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE public.parties;

COMMIT;

-- vim: expandtab shiftwidth=2
