\i spec/db/setup.sql

BEGIN;
  SELECT plan(4);

  PREPARE p1 AS SELECT api.register('boubou@teksol.info', 'monkeymonkey', '10eme', '', '');
  SELECT lives_ok('p1');

  PREPARE p2 AS SELECT api.sign_in('boubou@teksol.info', 'monkeymonkey');
  SELECT lives_ok('p2', 'can authenticate with correct email / password combo');

  PREPARE p3 AS SELECT api.sign_in('asdfouasdo', 'monkeymonkey');
  SELECT throws_ok('p3', '28P01' /* invalid_password */, 'Invalid email or password', 'fails sign_in with wrong email');

  PREPARE p4 AS SELECT api.sign_in('boubou@teksol.info', 'invalid password');
  SELECT throws_ok('p4', '28P01' /* invalid_password */, 'Invalid email or password', 'fails sign_in with wrong password');

  SELECT * FROM finish();
ROLLBACK;
