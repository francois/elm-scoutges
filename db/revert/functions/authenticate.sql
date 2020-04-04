-- Revert scoutges:functions/authenticate from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION authenticate(text, text);

COMMIT;

-- vim: expandtab shiftwidth=2
