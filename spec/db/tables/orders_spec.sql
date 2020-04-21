\i spec/db/setup.sql

BEGIN;
  SELECT plan(2);
  SELECT api.purge();

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('francois@teksol.info', 'boubou', '10th', 'Francois', '');
    SELECT lives_ok('p1', 'setup');
  RESET ROLE;

  SET LOCAL ROLE TO "10th";
    INSERT INTO api.parties(name, kind) VALUES ('Chouettes', 'troop');

    INSERT INTO api.party_addresses(party_slug, name, address)
    SELECT parties.slug, 'Mont-Plaisant', E'420 rue Mont-Plaisant\nSherbrooke'
    FROM api.parties;

    INSERT INTO api.orders(name, party_slug, bill_to, ship_to, checkout_on, start_on, end_on, return_on)
    SELECT 'Chouettes camp d''été', parties.slug, party_addresses.name, E'Camp Claret\nSt-Clin-Clin des Meuh-Meuh', '2020-07-05', '2020-07-07', '2020-07-12', '2020-07-19'
    FROM api.parties
    JOIN api.party_addresses ON party_addresses.party_slug = parties.slug;

    SELECT set_eq('SELECT unavailability_period FROM api.orders', array[daterange('2020-07-05', '2020-07-19', '[]')], 'unavailability_period value maintained properly');
  RESET ROLE;

  SELECT finish();
ROLLBACK;
