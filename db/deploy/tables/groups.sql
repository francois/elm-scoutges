-- Deploy scoutges:tables/groups to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE public.groups(
      id serial not null
    , name text not null check(length(name) > 1) primary key
    , pgrole text not null
    , registered_at timestamp with time zone not null default current_timestamp
  );

  COMMENT ON TABLE public.groups IS 'Records the list of scout groups that have registered on scoutges';

COMMIT;

-- vim: expandtab shiftwidth=2
