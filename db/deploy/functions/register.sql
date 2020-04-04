-- Deploy scoutges:functions/register to pg
-- requires: tables/users
-- requires: tables/active_jwt_tokens
-- requires: functions/generate_jwt_token

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.register(email text, password text) RETURNS json AS $$
  DECLARE
    result public.jwt_token;
  BEGIN
    INSERT INTO public.users(email, password, pguser)
    VALUES(register.email, register.password, 'authenticated');

    SELECT sign(row_to_json(r), current_setting('jwt.secret')) AS token
    FROM (
        SELECT
            user_role AS role
          , email AS sub
          , extract(epoch from current_timestamp + interval '1 hour')::integer AS exp
          , extract(epoch from current_timestamp)::integer AS iat
          , 'scoutges' AS aud
          , public.generate_jwt_token(register.email) AS jti
    ) AS r
    INTO result;

    RETURN ('{"token":"' || result.token || '"}')::json;
  END
  $$ LANGUAGE plpgsql;

  GRANT EXECUTE ON FUNCTION api.register TO anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
