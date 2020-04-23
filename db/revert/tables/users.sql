-- Revert scoutges:tables/users from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TABLE api.users CASCADE;

COMMIT;

-- vim: expandtab shiftwidth=2
