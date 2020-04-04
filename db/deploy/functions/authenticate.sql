-- Deploy scoutges:functions/authenticate to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.authenticate(email text, password text) RETURNS json AS $$
  DECLARE
    user_email text;
    user_role text;
    user_pass text;
    result public.jwt_token;
  BEGIN
    SELECT users.pguser, users.password, users.email
    INTO user_role, user_pass, user_email
    FROM users
    WHERE users.email = authenticate.email;

    IF user_role IS NULL THEN
      -- To prevent attackers guessing if the email exists or not, we make a for sure
      -- unsuccessful attempt at checking a password. This will take approximately the
      -- same amount of time as the crypt(text, text) call below, thus preventing timing
      -- attacks against this function.
      PERFORM crypt('boubou', '$2a$15$bwIigAojw.5eIR/ZFZmhEOo.f670p1GnksfxFXx79GL.76u8tKKy2');
      RAISE invalid_password USING message = 'Invalid email or password';
    END IF;

    IF user_pass <> crypt(authenticate.password, user_pass) THEN
      RAISE invalid_password USING message = 'Invalid email or password';
    END IF;

    SELECT sign(row_to_json(r), current_setting('jwt.secret')) AS token
    FROM (
        SELECT
            user_role AS role
          , email AS sub
          , extract(epoch from current_timestamp + interval '1 hour')::integer AS exp
          , extract(epoch from current_timestamp)::integer AS iat
          , 'scoutges' AS aud
          , public.generate_jwt_token(user_email) AS jti
    ) AS r
    INTO result;

    RETURN ('{"token":"' || result.token || '"}')::json;
  END;
  $$ LANGUAGE plpgsql;

  COMMENT ON FUNCTION api.authenticate IS 'The function that permits an anonymous user to become authenticated and receive a JWT claim';

  GRANT execute ON FUNCTION api.authenticate TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2