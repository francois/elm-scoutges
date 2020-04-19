-- Deploy scoutges:tables/customer_addresses to pg
-- requires: tables/customers

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE public.customer_addresses(
      id serial not null unique
    , customer_slug text not null references public.customers(slug) on update cascade on delete cascade
    , name text not null check(length(trim(name)) > 0)
    , address text not null check(length(trim(name)) > 0)
    , created_at timestamp with time zone not null default current_timestamp
    , updated_at timestamp with time zone not null default current_timestamp

    , pgrole text not null
        default current_user
        references public.groups(pgrole) on update cascade on delete restrict
    , unique(customer_slug, name)
  );

COMMIT;

-- vim: expandtab shiftwidth=2
