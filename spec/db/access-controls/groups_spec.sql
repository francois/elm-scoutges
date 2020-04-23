\i spec/db/setup.sql

BEGIN;
  SELECT plan(11);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('president@101st.org', 'president', '101st', '', '');
    SELECT lives_ok('p1');
  RESET ROLE;

  SET LOCAL ROLE TO anonymous;
    PREPARE p2 AS
      SELECT api.register(
          'baden@teksol.info'
        , 'monkeymonkey'
        , '47th'
        , 'Lord Robert Stephenson Smyth Baden Powell of Gilwell'
        , '03928341233');
    SELECT lives_ok('p2');
  RESET ROLE;

  SET LOCAL ROLE TO anonymous;
    SELECT throws_ok('SELECT name FROM api.groups', '42501' /* permission denied */, null, 'anonymous cannot read groups');
    SELECT throws_ok('UPDATE api.groups SET name = ''47eme''', '42501' /* permission denied */, null, 'anonymous cannot update groups');
    SELECT throws_ok('DELETE FROM api.groups', '42501' /* permission denied */, null, 'anonymous cannot delete groups');
  RESET ROLE;

  SET LOCAL ROLE TO "47th";
    SELECT set_eq('SELECT name FROM api.groups', array['47th'], 'authenticated can only see their own group');

    PREPARE p5 AS
      UPDATE api.groups
      SET name = '47ème', slug = 'patate';

    SELECT lives_ok('p5', 'authenticated can update name and slug');
    SELECT results_eq('SELECT name, slug FROM api.groups', 'VALUES(''47ème'', ''patate'')', 'autheticated can change their name and slug');
  RESET ROLE;

  SET LOCAL ROLE TO privileged;
    SELECT set_eq('SELECT name FROM api.groups', array['47ème', '101st'], 'group could not rename other groups');
    SELECT set_eq('SELECT slug FROM api.groups', array['patate', '101st'], 'group could not change other group slugs');
  RESET ROLE;

  SELECT * FROM finish();
ROLLBACK;
