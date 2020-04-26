\i spec/db/setup.sql

BEGIN;
  SELECT plan(18);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('francois@teksol.info', 'monkey', '10eme', 'Francois', '');
    SELECT lives_ok('p1');

    PREPARE p2 AS SELECT api.register('raphael@teksol.info', 'monkey', '47eme', 'Raphael', '');
    SELECT lives_ok('p2');
  RESET ROLE;

  SET LOCAL ROLE TO "47eme";
    SELECT lives_ok('INSERT INTO api.parties(name, kind) VALUES (''10eme'', ''supplier'')');
    SELECT slug FROM api.parties WHERE name = '10eme' \gset

    -- assert that api.edit_party(text) returns the exact row that we want, when there are no addresses
    SELECT set_eq('SELECT json_object_keys(r) FROM api.edit_party(''' || :'slug' || ''') r'
              , array['name', 'kind', 'slug', 'created_at', 'updated_at', 'addresses'], 'no extraneous keys');

    SELECT set_eq('SELECT r->>''slug'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array[:'slug'], 'slug matches');
    SELECT set_eq('SELECT r->>''name'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array['10eme'], 'name matches');
    SELECT set_eq('SELECT r->>''kind'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array['supplier'], 'supplier matches');
    SELECT set_eq('SELECT json_array_length(r->''addresses'') FROM api.edit_party(''' || :'slug' || ''') r'
              , array[0], 'no addresses');

    -- now, add an address and run the assertions again
    PREPARE p3 AS
      INSERT INTO api.party_addresses(party_slug, name, address)
      VALUES(:'slug', 'mailing', '#111-111 111th ave');
    SELECT lives_ok('p3');

    SELECT set_eq('SELECT json_object_keys(r) FROM api.edit_party(''' || :'slug' || ''') r'
              , array['name', 'kind', 'slug', 'created_at', 'updated_at', 'addresses'], 'no extraneous keys');

    SELECT set_eq('SELECT r->>''slug'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array[:'slug'], 'slug matches');
    SELECT set_eq('SELECT r->>''name'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array['10eme'], 'name matches');
    SELECT set_eq('SELECT r->>''kind'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array['supplier'], 'supplier matches');
    SELECT set_eq('SELECT json_array_length(r->''addresses'') FROM api.edit_party(''' || :'slug' || ''') r'
              , array[1], 'one address');
    SELECT set_eq('SELECT json_object_keys(r->''addresses''->0) FROM api.edit_party(''' || :'slug' || ''') r'
              , array['name', 'address'], 'no extraneous address fields');
    SELECT set_eq('SELECT r->''addresses''->0->>''name'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array['mailing'], 'returns correct address name');
    SELECT set_eq('SELECT r->''addresses''->0->>''address'' FROM api.edit_party(''' || :'slug' || ''') r'
              , array['#111-111 111th ave'], 'returns correct address');
  RESET ROLE;

  SELECT finish();
ROLLBACK;
