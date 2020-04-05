\i spec/db/_helper.sql

BEGIN;
  SELECT plan(3);

  INSERT INTO public.users(email, password, pguser) VALUES ('boubou@teksol.info', 'monkeymonkey', 'authenticated');

  PREPARE p2 AS SELECT api.sign_in('boubou@teksol.info', 'monkeymonkey');
  SELECT lives_ok('p2', 'can authenticate with correct email / password combo');

  PREPARE p3 AS SELECT api.sign_in('asdfouasdo', 'monkeymonkey');
  SELECT throws_ok('p3', '28P01' /* invalid_password */, 'Invalid email or password', 'fails sign_in with wrong email');

  PREPARE p4 AS SELECT api.sign_in('boubou@teksol.info', 'invalid password');
  SELECT throws_ok('p4', '28P01' /* invalid_password */, 'Invalid email or password', 'fails sign_in with wrong email');

  SELECT * FROM finish();
ROLLBACK;
