-- Deploy scoutges:extensions/unaccent to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE EXTENSION unaccent;

COMMIT;

-- vim: expandtab shiftwidth=2
