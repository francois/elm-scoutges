-- Deploy scoutges:tables/users to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE api.users(
      id serial not null unique
    , email text not null check(email ~ '^.+@.+[.][a-z]{2,}$') primary key
    , password text not null
    , name text not null
    , phone text not null
    , group_name text not null default current_user references api.groups on update cascade on delete cascade
    , pgrole text not null default current_user references api.groups(pgrole) on update cascade on delete cascade
    , registered_at timestamp with time zone not null default current_timestamp
  );

  COMMENT ON TABLE api.users IS 'The central repository of authentication-related queries.';
  COMMENT ON COLUMN api.users.password IS 'The encrypted password. Even though the column''s name is simply ''password'', the password is still stored in an encrypted format, through the use of a database trigger.';

COMMIT;

-- vim: expandtab shiftwidth=2
