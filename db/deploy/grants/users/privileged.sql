-- Deploy scoutges-test:grants/users/privileged to pg

SET client_min_messages TO 'warning';

BEGIN;

  GRANT privileged TO postgrest;

COMMIT;

-- vim: expandtab shiftwidth=2
