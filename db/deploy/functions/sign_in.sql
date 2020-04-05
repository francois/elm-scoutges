-- Deploy scoutges:functions/authenticate to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.sign_in(email text, password text) RETURNS json AS $$
  DECLARE
    user_email text;
    user_role text;
    user_pass text;
    result public.jwt_token;
  BEGIN
    SELECT users.pguser, users.password, users.email
    INTO user_role, user_pass, user_email
    FROM users
    WHERE users.email = sign_in.email;

    IF user_role IS NULL THEN
      -- To prevent attackers guessing if the email exists or not, we make a for sure
      -- unsuccessful attempt at checking a password. This will take approximately the
      -- same amount of time as the crypt(text, text) call below, thus preventing timing
      -- attacks against this function.
      PERFORM crypt('boubou', gen_salt('bf', coalesce(current_setting('security.bf_strength', true), '15')::integer));
      RAISE invalid_password USING message = 'Invalid email or password';
    END IF;

    IF user_pass <> crypt(sign_in.password, user_pass) THEN
      RAISE invalid_password USING message = 'Invalid email or password';
    END IF;

    SELECT jwt_sign(row_to_json(r), current_setting('jwt.secret')) AS token
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

    RETURN result;
  END;
  $$ LANGUAGE plpgsql;

  COMMENT ON FUNCTION api.sign_in IS 'The function that permits an anonymous user to become authenticated and receive a JWT claim';

  GRANT execute ON FUNCTION api.sign_in TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
