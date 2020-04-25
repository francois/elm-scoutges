-- Deploy scoutges:functions/register to pg
-- requires: tables/users
-- requires: tables/active_jwt_tokens
-- requires: functions/generate_jwt_token

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.register(email text, password text, group_name text, name text, phone text) RETURNS json AS $$
  DECLARE
    result public.jwt_token;
    pgrole text;
  BEGIN
    SELECT public.create_group_role(group_name) INTO pgrole;

    EXECUTE 'SET LOCAL ROLE TO ' || quote_ident(pgrole);
      INSERT INTO api.groups(name, slug)
      VALUES (register.group_name, public.slugify(register.group_name));

      INSERT INTO api.users(email, password, name, phone, group_name)
      VALUES(register.email, register.password, register.name, register.phone, register.group_name);
    RESET ROLE;

    INSERT INTO public.que_jobs(job_class, args)
    VALUES('Scoutges::Jobs::SendWelcomeEmail', jsonb_build_array(register.email));

    SELECT jwt_sign(row_to_json(r), current_setting('jwt.secret')) AS token
    FROM (
        SELECT
            pgrole AS role
          , email AS sub
          , extract(epoch from current_timestamp + interval '9 days')::integer AS exp
          , extract(epoch from current_timestamp)::integer AS iat
          , 'scoutges' AS aud
          , public.generate_jwt_token(register.email) AS jti
    ) AS r
    INTO result;

    RETURN result;
  END
  $$ LANGUAGE plpgsql;

  COMMENT ON FUNCTION api.register IS 'The method through which people can register to be users of the app';

  REVOKE ALL PRIVILEGES ON FUNCTION api.register(text, text, text, text, text) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION api.register(text, text, text, text, text) TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
