-- Deploy scoutges:functions/pre_request_authenticator to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.pre_request_authenticator() RETURNS boolean AS $$
  DECLARE
    result boolean;
  BEGIN
    IF current_setting('request.jwt.claim.jti', true) IS NULL THEN
      -- Incoming request is made by an anonymous user, always allow anonymous requests
      RETURN true;
    END IF;

    SELECT true
    INTO result
    FROM public.active_jwt_tokens
    WHERE jid = current_setting('request.jwt.claim.jti', true)::uuid
      AND email = current_setting('request.jwt.claim.sub', true);

    IF found THEN
      RETURN true;
    END IF;

    RAISE insufficient_privilege USING hint = 'Expired or unauthorized jti / sub pair';
    RETURN result;
  END
  $$ LANGUAGE plpgsql;

  GRANT EXECUTE ON FUNCTION public.pre_request_authenticator() TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
