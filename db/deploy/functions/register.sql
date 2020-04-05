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

    INSERT INTO public.que_jobs(job_class, args)
    VALUES('Scoutges::Jobs::SendWelcomeEmail', jsonb_build_array(register.email));

    SELECT jwt_sign(row_to_json(r), current_setting('jwt.secret')) AS token
    FROM (
        SELECT
            'authenticated' AS role
          , email AS sub
          , extract(epoch from current_timestamp + interval '1 hour')::integer AS exp
          , extract(epoch from current_timestamp)::integer AS iat
          , 'scoutges' AS aud
          , public.generate_jwt_token(register.email) AS jti
    ) AS r
    INTO result;

    RETURN result;
  END
  $$ LANGUAGE plpgsql;

  COMMENT ON FUNCTION api.register IS 'The method through which people can register to be users of the app';

  GRANT execute ON FUNCTION api.register TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
