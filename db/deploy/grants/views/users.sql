-- Deploy scoutges:grants/views/users to pg
-- requires: views/users

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON api.users FROM PUBLIC;

  GRANT SELECT ON api.users TO authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
