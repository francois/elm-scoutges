-- Deploy scoutges:functions/identify_user to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TYPE identity_result AS(
      email text
    , password text
    , pgrole text
  );

  CREATE OR REPLACE FUNCTION public.identify_user(email text) RETURNS identity_result AS $$
    SELECT users.email, users.password, groups.pgrole
    FROM api.users
    JOIN api.groups ON groups.name = users.group_name
    WHERE users.email = identify_user.email;
  $$ LANGUAGE sql SECURITY DEFINER;

  REVOKE ALL PRIVILEGES ON FUNCTION public.identify_user(text) FROM PUBLIC;
  ALTER FUNCTION public.identify_user(text) OWNER TO privileged;
  GRANT EXECUTE ON FUNCTION public.identify_user(text) TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
