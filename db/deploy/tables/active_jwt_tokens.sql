-- Deploy scoutges:tables/active_jwt_tokens to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE public.active_jwt_tokens(
      id serial primary key
    , jid uuid unique default gen_random_uuid()
    , email text not null references api.users(email) on update cascade on delete cascade
  );

  COMMENT ON TABLE public.active_jwt_tokens IS 'Records active JWT tokens in the wild. If a row does not exist here, then the token is invalid and must be rejected. This table is to be used in conjuction with PostgREST''s pre-request function, in order to confirm the validity of the token.';

COMMIT;

-- vim: expandtab shiftwidth=2
