-- Revert scoutges:functions/edit_party from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION api.edit_party(text);

COMMIT;

-- vim: expandtab shiftwidth=2
