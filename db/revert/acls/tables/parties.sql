-- Revert scoutges:acls/tables/parties from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP POLICY self_crud ON public.parties;
  ALTER TABLE public.parties DISABLE ROW LEVEL SECURITY;
  REVOKE USAGE ON SEQUENCE parties_id_seq FROM authenticated;
  REVOKE ALL PRIVILEGES ON public.parties FROM authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
