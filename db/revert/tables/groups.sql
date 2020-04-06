-- Revert scoutges:tables/groups from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE public.groups;

COMMIT;

-- vim: expandtab shiftwidth=2
