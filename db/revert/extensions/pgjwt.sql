-- Revert scoutges:extensions/pgjwt from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.jwt_test(text);

  DROP FUNCTION public.url_encode(bytea);
  DROP FUNCTION public.url_decode(text);
  DROP FUNCTION public.algorithm_sign(text, text, text);
  DROP FUNCTION public.sign(json, text, text);
  DROP FUNCTION public.verify(text, text, text);

  DROP TYPE jwt_token;

COMMIT;

-- vim: expandtab shiftwidth=2
