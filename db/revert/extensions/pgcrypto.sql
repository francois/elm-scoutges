-- Revert scoutges:extensions/pgcrypto from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP EXTENSION IF EXISTS "pgcrypto";

COMMIT;

-- vim: expandtab shiftwidth=2
