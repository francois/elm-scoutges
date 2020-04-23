-- Revert scoutges-test:grants/users/privileged from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE privileged FROM postgrest;

COMMIT;

-- vim: expandtab shiftwidth=2
