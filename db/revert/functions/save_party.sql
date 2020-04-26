-- Revert scoutges:functions/save_party from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION api.save_party(json);

COMMIT;

-- vim: expandtab shiftwidth=2
