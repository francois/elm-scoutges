-- Deploy scoutges:extensions/citext to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE EXTENSION "citext";

COMMIT;

-- vim: expandtab shiftwidth=2
