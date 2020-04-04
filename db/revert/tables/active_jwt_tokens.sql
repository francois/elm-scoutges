-- Revert scoutges:tables/active_jwt_tokens from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE public.active_jwt_tokens;

COMMIT;

-- vim: expandtab shiftwidth=2
