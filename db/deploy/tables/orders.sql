-- Deploy scoutges:tables/orders to pg
-- requires: tables/parties
-- requires: tables/party_addresses
-- requires: sequences/order_nos

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TABLE api.orders(
      id serial not null unique

    , name text not null
    , slug text not null unique default generate_serial_nos(8)
    , party_slug text not null
        references api.parties(slug) on update cascade on delete restrict
    , bill_to text not null
    , ship_to text

    , checkout_on date not null
    , start_on date not null
    , end_on date not null
    , return_on date not null
    , unavailability_period daterange not null generated always as(daterange(checkout_on, return_on, '[]')) stored

    , created_at timestamp with time zone not null default current_timestamp
    , updated_at timestamp with time zone not null default current_timestamp

    , pgrole text not null default current_user
        references api.groups(pgrole)
        on update cascade on delete restrict

    , constraint checkout_on_before_start_on check(checkout_on <= start_on)
    , constraint start_on_before_end_on check(start_on <= end_on)
    , constraint end_on_before_return_on check(end_on <= return_on)

    , foreign key(party_slug, bill_to)
        references api.party_addresses(party_slug, name)
        on update cascade on delete restrict
  );

  COMMENT ON TABLE api.orders IS 'The record of when products/kits/consumables were checked out, and possibly returned.';
  COMMENT ON COLUMN api.orders.unavailability_period IS 'An inclusive date range that holds all the dates in which instances on this order will be unavailable.';
  COMMENT ON COLUMN api.orders.bill_to IS 'The address to send the invoice to, after the event is over';
  COMMENT ON COLUMN api.orders.ship_to IS 'The address where the products are to be delivered; optional. Free form text.';

COMMIT;

-- vim: expandtab shiftwidth=2
