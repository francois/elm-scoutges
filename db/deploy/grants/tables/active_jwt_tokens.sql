-- Deploy scoutges:grants/active_jwt_tokens to pg
-- requires: tables/active_jwt_tokens

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON public.active_jwt_tokens FROM PUBLIC;

  GRANT SELECT(jid, email)
  ON public.active_jwt_tokens
  TO anonymous, authenticated, privileged;

  GRANT INSERT(email)
  ON public.active_jwt_tokens
  TO privileged;

  GRANT USAGE ON SEQUENCE active_jwt_tokens_id_seq
  TO privileged;

COMMIT;

-- vim: expandtab shiftwidth=2
