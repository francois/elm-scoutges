-- Deploy scoutges:grants/users to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  GRANT SELECT, INSERT ON public.users TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
