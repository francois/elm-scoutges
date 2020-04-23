-- Revert scoutges:triggers/canonicalize_user_email from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TRIGGER canonicalize_user_email ON api.users;

COMMIT;

-- vim: expandtab shiftwidth=2
