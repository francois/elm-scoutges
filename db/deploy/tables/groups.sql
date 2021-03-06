-- Deploy scoutges:tables/groups to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE api.groups(
      id serial not null unique
    , name text not null check(length(name) > 1) primary key
    , slug text not null unique
    , pgrole text not null unique default current_user
    , registered_at timestamp with time zone not null default current_timestamp
  );

  COMMENT ON TABLE api.groups IS 'Records the list of scout groups that have registered on scoutges';

COMMIT;

-- vim: expandtab shiftwidth=2
