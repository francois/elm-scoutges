-- Revert scoutges:tables/groups from pg

SET client_min_messages TO 'warning';

BEGIN;
  CREATE OR REPLACE FUNCTION public._purge() RETURNS void AS $$
  DECLARE
    row record;
  BEGIN
    FOR row IN SELECT pgrole FROM api.groups LOOP
      EXECUTE 'DROP ROLE ' || quote_ident(row.pgrole);
    END LOOP;

    TRUNCATE api.groups, que_jobs CASCADE;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  SELECT public._purge();
  DROP FUNCTION public._purge();

  DROP TABLE api.groups;

COMMIT;

-- vim: expandtab shiftwidth=2
