-- Revert scoutges:functions/pre_request_authenticator from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.pre_request_authenticator();

COMMIT;

-- vim: expandtab shiftwidth=2
