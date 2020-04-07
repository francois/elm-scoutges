-- Revert scoutges:functions/invite from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION api.invite(text[]);

COMMIT;

-- vim: expandtab shiftwidth=2
