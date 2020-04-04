-- Revert scoutges:constraints/enforce_existence_of_users_pguser from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TRIGGER IF EXISTS public.check_role_exists ON public.users;

COMMIT;

-- vim: expandtab shiftwidth=2
