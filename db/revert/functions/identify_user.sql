-- Revert scoutges:functions/identify_user from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.identify_user(text);
  DROP TYPE identity_result;

COMMIT;

-- vim: expandtab shiftwidth=2
