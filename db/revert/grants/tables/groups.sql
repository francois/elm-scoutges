-- Revert scoutges:grants/tables/groups from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE public.groups FROM PUBLIC;

COMMIT;

-- vim: expandtab shiftwidth=2
