-- Revert scoutges:policies/tables/groups from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON public.groups;
  DROP POLICY anon_sign_in ON public.groups;

COMMIT;

-- vim: expandtab shiftwidth=2
