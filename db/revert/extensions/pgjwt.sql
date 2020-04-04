-- Revert scoutges:extensions/pgjwt from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.jwt_url_encode(bytea);
  DROP FUNCTION public.jwt_url_decode(text);
  DROP FUNCTION public.jwt_algorithm_sign(text, text, text);
  DROP FUNCTION public.jwt_sign(json, text, text);
  DROP FUNCTION public.jwt_verify(text, text, text);

  DROP TYPE jwt_token;

COMMIT;

-- vim: expandtab shiftwidth=2
