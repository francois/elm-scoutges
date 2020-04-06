-- Revert scoutges:functions/register from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION api.register(text, text, text, text, text);

COMMIT;

-- vim: expandtab shiftwidth=2
