-- Revert scoutges:policies/users from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY group_crud ON public.users;
  DROP POLICY privileged_sign_in ON public.users;

COMMIT;

-- vim: expandtab shiftwidth=2
