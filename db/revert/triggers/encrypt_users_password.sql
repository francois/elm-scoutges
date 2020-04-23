-- Revert scoutges:triggers/encrypt_users_password from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP TRIGGER IF EXISTS encrypt_users_password ON api.users;

COMMIT;

-- vim: expandtab shiftwidth=2
