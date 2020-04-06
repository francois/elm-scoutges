-- Deploy scoutges:grants/schemas/api to pg
-- requires: schemas/api

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON SCHEMA api FROM PUBLIC;

  GRANT usage ON SCHEMA api TO anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
