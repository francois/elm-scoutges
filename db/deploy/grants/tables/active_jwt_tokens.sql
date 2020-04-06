-- Deploy scoutges:grants/active_jwt_tokens to pg
-- requires: tables/active_jwt_tokens

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON public.active_jwt_tokens FROM PUBLIC;

  GRANT INSERT ON public.active_jwt_tokens TO anonymous, authenticated;
  GRANT SELECT(jid, email) ON public.active_jwt_tokens TO anonymous, authenticated;
  GRANT USAGE ON SEQUENCE active_jwt_tokens_id_seq TO anonymous, authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
