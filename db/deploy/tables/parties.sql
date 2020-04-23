-- Deploy scoutges:tables/parties to pg
-- requires: tables/groups

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE api.parties(
      id serial not null unique
    , slug text not null primary key default public.generate_serial_nos(8)
    , name text not null
    , kind party_kind not null default 'customer'
    , created_at timestamp with time zone not null default current_timestamp
    , updated_at timestamp with time zone not null default current_timestamp

    , pgrole text not null
        default current_user
        references api.groups(pgrole) on update cascade on delete restrict
  );

  COMMENT ON TABLE api.parties IS 'The list of all parties a group makes business with. \"parties\" here is taken in a large sense: it includes suppliers, troops and actual leasers of products of this scout group.';
  COMMENT ON COLUMN api.parties.kind IS 'Describes the relationship of ourselves towards this party; are they customers of ours, or are they one of our troops, or an external group?';

COMMIT;

-- vim: expandtab shiftwidth=2
