-- Deploy scoutges:grants/schemas/public to pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON SCHEMA public FROM PUBLIC;

  GRANT ALL PRIVILEGES ON SCHEMA public TO current_user;
  GRANT USAGE ON SCHEMA public TO anonymous, authenticated, postgrest;

COMMIT;

-- vim: expandtab shiftwidth=2
