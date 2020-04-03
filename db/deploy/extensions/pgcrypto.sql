-- Deploy scoutges:extensions/pgcrypto to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE EXTENSION "pgcrypto";

COMMIT;

-- vim: expandtab shiftwidth=2
