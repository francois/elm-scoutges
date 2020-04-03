-- Deploy scoutges:schemas/api to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE SCHEMA api;
  COMMENT ON SCHEMA api IS 'The publicly accessible schema where PostgREST will read from. Functions, views and tables in this schema are potentially reachable by PostgREST, subject to regular PostgreSQL privilege rules.';
  GRANT usage ON SCHEMA api TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
