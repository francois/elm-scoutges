-- Revert scoutges:policies/users from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY anonymous_select ON public.users;
  DROP POLICY self_select ON public.users;
  DROP POLICY self_edit ON public.users;

COMMIT;

-- vim: expandtab shiftwidth=2
