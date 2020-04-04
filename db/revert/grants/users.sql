-- Revert scoutges:grants/users from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE SELECT, INSERT ON public.users FROM anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
