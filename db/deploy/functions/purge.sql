-- Deploy scoutges-test:functions/purge to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.purge() RETURNS void AS $$
  DECLARE
    row record;
  BEGIN
    TRUNCATE api.users CASCADE;

    FOR row IN SELECT pgrole FROM api.groups LOOP
      EXECUTE 'DROP ROLE ' || quote_ident(row.pgrole);
    END LOOP;

    TRUNCATE api.groups, que_jobs CASCADE;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  COMMENT ON FUNCTION api.purge() IS 'A function to be used only during tests that completely wipes out the database from all user-generated records. Any system-level configuration records will stay in.';

  REVOKE ALL PRIVILEGES ON FUNCTION api.purge() FROM PUBLIC;

  GRANT EXECUTE ON FUNCTION api.purge() TO anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
