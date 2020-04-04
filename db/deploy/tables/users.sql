-- Deploy scoutges:tables/users to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE public.users(
      id serial
    , email citext not null unique check(email ~ '^.+@.+[.][a-z]{2,}$')
    , pguser text not null unique
    , password text not null
    , registered_at timestamp with time zone not null default current_timestamp
  );

  COMMENT ON TABLE public.users IS 'The central repository of authentication-related queries.';
  COMMENT ON COLUMN public.users.pguser IS 'The name of the actual PostgreSQL role that this user was created with.';
  COMMENT ON COLUMN public.users.password IS 'The encrypted password. Even though the column''s name is simply ''password'', the password is still stored in an encrypted format, through the use of a database trigger.';

COMMIT;

-- vim: expandtab shiftwidth=2
