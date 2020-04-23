-- Deploy scoutges:functions/authenticate to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.sign_in(email text, password text) RETURNS json AS $$
  DECLARE
    identity identity_result;
    result public.jwt_token;
  BEGIN
    SELECT public.identify_user(sign_in.email) INTO identity;
    -- IF not_found THEN ... END IF

    IF identity.email IS NULL THEN
      -- To prevent attackers guessing if the email exists or not, we throttle them
      -- by making an unsuccessful attempt at checking a password. This takes approximately the
      -- same amount of time as a successful check, hence this introduces friction for attackers
      -- and may help us against script-kiddy attacks.
      PERFORM crypt('boubou', gen_salt('bf', coalesce(current_setting('security.bf_strength', true), '15')::integer));
      RAISE invalid_password USING message = 'Invalid email or password';
    END IF;

    IF identity.password <> crypt(sign_in.password, identity.password) THEN
      RAISE invalid_password USING message = 'Invalid email or password';
    END IF;

    SELECT jwt_sign(row_to_json(r), current_setting('jwt.secret')) AS token
    FROM (
        SELECT
            identity.pgrole AS role
          , identity.email AS sub
          , extract(epoch from current_timestamp + interval '48 hours')::integer AS exp
          , extract(epoch from current_timestamp)::integer AS iat
          , 'scoutges' AS aud
          , public.generate_jwt_token(identity.email) AS jti
    ) AS r
    INTO result;

    RETURN result;
  END;
  $$ LANGUAGE plpgsql;

  COMMENT ON FUNCTION api.sign_in IS 'The function that permits an anonymous user to become authenticated and receive a JWT claim';

  GRANT execute ON FUNCTION api.sign_in TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
