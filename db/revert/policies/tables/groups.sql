-- Revert scoutges:policies/tables/groups from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_edit ON public.groups;
  DROP POLICY anonymous_insert ON public.groups

COMMIT;

-- vim: expandtab shiftwidth=2
