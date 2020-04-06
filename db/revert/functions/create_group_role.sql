-- Revert scoutges:functions/create_group_role from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.create_group_role(text);

COMMIT;

-- vim: expandtab shiftwidth=2
