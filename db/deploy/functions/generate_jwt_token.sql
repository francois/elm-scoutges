-- Deploy scoutges:functions/generate_jwt_token to pg
-- requires: extensions/pgcrypto
-- requires: tables/active_jwt_tokens

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.generate_jwt_token(email text) RETURNS text AS $$
    INSERT INTO public.active_jwt_tokens(email)
    VALUES (generate_jwt_token.email)
    RETURNING jid::text;
  $$ LANGUAGE sql;

  GRANT EXECUTE ON FUNCTION public.generate_jwt_token(text) TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
