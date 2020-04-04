-- Revert scoutges:grants/active_jwt_tokens from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE INSERT ON public.active_jwt_tokens FROM anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
