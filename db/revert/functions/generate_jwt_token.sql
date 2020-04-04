-- Revert scoutges:functions/generate_jwt_token from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.generate_jwt_token(text);

COMMIT;

-- vim: expandtab shiftwidth=2
