-- Revert scoutges:casts/jwt_token_to_json from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.jwt_token_to_json(jwt_token) CASCADE;

COMMIT;

-- vim: expandtab shiftwidth=2
