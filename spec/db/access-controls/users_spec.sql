\i spec/db/setup.sql

BEGIN;
  SELECT plan(6);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register($1, 'monkeymonkey', $2, 'Bob ' || random(), '');
    SELECT lives_ok('EXECUTE p1(''bob@teksol.info'', ''1er Drummondville'')', 'anonymous can register');
  RESET ROLE;

  SET LOCAL ROLE TO "1er Drummondville";
    SELECT lives_ok('INSERT INTO api.users(email, password, group_name, name, phone) VALUES (''john@teksol.info'', ''monkey'', ''1er Drummondville'', ''John'', '''')');
  RESET ROLE;

  SET LOCAL ROLE TO anonymous;
    SELECT lives_ok('EXECUTE p1(''peter@teksol.info'', ''4ème St-Hubert'')');
  RESET ROLE;

  SET LOCAL ROLE TO "1er Drummondville";
    SET LOCAL "request.jwt.claim.email" TO 'john@teksol.info';

    PREPARE p4 AS SELECT email FROM api.users;
    SELECT set_eq('p4', array['bob@teksol.info', 'john@teksol.info'], 'can only view records within my own group');

    RESET "request.jwt.claim.email";
  RESET ROLE;

  SET LOCAL ROLE TO "4ème St-Hubert";
    SET LOCAL "request.jwt.claim.email" TO 'peter@teksol.info';

    PREPARE p5 AS UPDATE api.users SET name = 'Peter' RETURNING email, name;
    SELECT results_eq('p5', 'VALUES(''peter@teksol.info'', ''Peter'')', 'can only edit my own record');
    RESET "request.jwt.claim.email";
  RESET ROLE;

  SELECT finish();
ROLLBACK;
