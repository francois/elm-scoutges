-- Deploy scoutges-test:extensions/pgtap to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE EXTENSION IF NOT EXISTS pgtap;

COMMIT;

-- vim: expandtab shiftwidth=2
