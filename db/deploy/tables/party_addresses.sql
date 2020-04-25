-- Deploy scoutges:tables/party_addresses to pg
-- requires: tables/parties

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE api.party_addresses(
      id serial not null unique
    , party_slug text not null references api.parties(slug) on update cascade on delete cascade
    , slug text not null unique default public.generate_serial_nos(10)
    , name text not null check(length(trim(name)) > 0)
    , address text not null check(length(trim(name)) > 0)
    , created_at timestamp with time zone not null default current_timestamp
    , updated_at timestamp with time zone not null default current_timestamp

    , pgrole text not null
        default current_user
        references api.groups(pgrole) on update cascade on delete restrict
    , unique(party_slug, name)
  );

COMMIT;

-- vim: expandtab shiftwidth=2
