-- Deploy scoutges-test:functions/seed_user to pg
-- requires: scoutges:tables/groups
-- requires: scoutges:tables/users

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.seed_user(email text, password text, name text, phone text, group_name text) RETURNS void AS $$
  DECLARE
    group_exists boolean;
  BEGIN
    INSERT INTO api.users(email, password, name, phone, group_name, pgrole)
    VALUES(seed_user.email, seed_user.password, seed_user.name, seed_user.phone, seed_user.group_name, seed_user.group_name);

    RETURN;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  REVOKE ALL PRIVILEGES ON FUNCTION api.seed_user(text, text, text, text, text) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION api.seed_user(text, text, text, text, text) TO anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
