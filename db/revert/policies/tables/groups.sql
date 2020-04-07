-- Revert scoutges:policies/tables/groups from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY anonymous_select ON public.groups;
  DROP POLICY self_select ON public.groups;
  DROP POLICY self_edit ON public.groups;

COMMIT;

-- vim: expandtab shiftwidth=2
