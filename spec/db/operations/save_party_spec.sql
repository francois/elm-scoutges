\i spec/db/setup.sql

BEGIN;
  SELECT plan(12);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('francois@teksol.info', 'monkey', '10eme', 'Francois', '');
    SELECT lives_ok('p1');
  RESET ROLE;

  SET LOCAL ROLE TO "10eme";
    SELECT lives_ok('INSERT INTO api.parties(name, kind) VALUES (''Duquette'', ''supplier'')');
    SELECT slug FROM api.parties \gset
    SELECT lives_ok('INSERT INTO api.party_addresses(party_slug, name, address) VALUES (''' || :'slug' || ''', ''office'', ''200 12th ave'')');

    PREPARE p2 AS
      SELECT api.save_party(json_build_object('name', 'Pâtisseries Duquette Inc.', 'slug', :'slug', 'kind', 'customer', 'addresses', json_build_array()));
    SELECT lives_ok('p2', 'can save without error');

    PREPARE p3 AS SELECT slug, name, kind FROM api.parties WHERE slug = :'slug';
    SELECT set_eq('p3', 'VALUES (''' || :'slug' || ''', ''Pâtisseries Duquette Inc.'', ''customer''::party_kind)', 'party info updated');

    PREPARE p4 AS SELECT count(*) FROM api.party_addresses WHERE party_slug = :'slug';
    SELECT results_eq('p4', array[0]::bigint[], 'deleted all addresses');

    PREPARE p5 AS
      SELECT api.save_party(json_build_object('name', 'Pâtisseries Duquette Inc.', 'slug', :'slug', 'kind', 'customer', 'addresses'
          , json_build_array(
                json_build_object('name', 'plant', 'address', '500 12th ave')
              , json_build_object('name', 'office', 'address', '200 12th ave')
          )
      )
    );
    SELECT lives_ok('p5', 'can save addresses without error');

    PREPARE p6 AS SELECT name, address FROM api.party_addresses WHERE party_slug = :'slug';
    SELECT set_eq('p6', $$ VALUES('plant', '500 12th ave'), ('office', '200 12th ave') $$, 'saved addresses');

    PREPARE p7 AS
      SELECT api.save_party(json_build_object('name', 'Centre Julien-Ducharme', 'kind', 'supplier'
            , 'addresses', json_build_array(json_build_object('name', 'main', 'address', '1671 Duplessis Rd'))));
    SELECT lives_ok('p7', 'can insert without error');

    SELECT slug FROM api.parties WHERE name = 'Centre Julien-Ducharme' \gset
    SELECT isnt(:'slug', null::text, 'inserted party to database');

    PREPARE p8 AS SELECT name, address FROM api.party_addresses WHERE party_slug = :'slug';
    SELECT set_eq('p8', $$ VALUES('main', '1671 Duplessis Rd') $$, 'address correctly inserted');
  RESET ROLE;

  SELECT finish();
ROLLBACK;
