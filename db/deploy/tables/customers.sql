-- Deploy scoutges:tables/customers to pg
-- requires: tables/groups

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE public.customers(
      id serial not null unique
    , slug text not null primary key default public.generate_serial_nos(8)
    , name text not null
    , external boolean not null default true
    , created_at timestamp with time zone not null default current_timestamp
    , updated_at timestamp with time zone not null default current_timestamp

    , pgrole text not null
        default current_user
        references public.groups(pgrole) on update cascade on delete restrict
  );

  COMMENT ON TABLE public.customers IS 'The list of all customers a group makes business with. \"Customers\" here is taken in a large sense: it includes suppliers, troops and actual leasers of products of this scout group.';

COMMIT;

-- vim: expandtab shiftwidth=2
