\i spec/db/setup.sql

BEGIN;
  SELECT plan(4);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('francois@teksol.info', 'monkeymonkey', '10ème', 'Francois', '');
    SELECT lives_ok('p1', 'register 1');

    PREPARE p2 AS SELECT api.register('raphael@teksol.info', 'monkeymonkey', '47eme', 'Francois', '');
    SELECT lives_ok('p2', 'register 2');
  RESET ROLE;

  SET LOCAL ROLE TO "47eme";
    INSERT INTO api.parties(name) VALUES ('ASC47');
    INSERT INTO api.parties(name) VALUES ('Ville de Sherbrooke');
  RESET ROLE;

  SET LOCAL ROLE TO "10ème";
    INSERT INTO api.parties(name) VALUES ('ASC10');
    INSERT INTO api.parties(name) VALUES ('District de l''érable');
  RESET ROLE;

  SET LOCAL ROLE TO "10ème";
    SELECT set_eq('SELECT name FROM api.parties', array['ASC10', 'District de l''érable'], 'can only see own parties');
  RESET ROLE;

  SELECT * FROM finish();
ROLLBACK;
