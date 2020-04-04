-- Deploy scoutges:functions/authenticate to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.authenticate(email text, password text) RETURNS text AS $$
  DECLARE
    user_role text;
    user_pass text;
    result public.jwt_token;
  BEGIN
    SELECT pguser, encrypted_password
    INTO user_role, user_pass
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
          , email AS email
          , extract(epoch from current_timestamp + interval '1 hour')::integer AS exp
    ) AS r
    INTO result;

    RETURN result;
  END;
  $$ LANGUAGE plpgsql;

  COMMENT ON FUNCTION public.authenticate IS 'The function that permits an anonymous user to become authenticated and receive a JWT claim';

  GRANT execute ON FUNCTION public.authenticate TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
