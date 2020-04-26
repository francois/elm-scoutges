-- Revert scoutges:functions/save_full_party from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION api.save_full_party(json);

COMMIT;

-- vim: expandtab shiftwidth=2
