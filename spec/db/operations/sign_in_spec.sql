\i spec/db/setup.sql

BEGIN;
  SELECT plan(5);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('boubou@teksol.info', 'monkeymonkey', '10eme', '', '');
    SELECT lives_ok('p1');
  RESET ROLE;

  SET LOCAL ROLE TO anonymous;
    SELECT ok(p.valid, 'returns valid token from api.sign_in when using correct credentials')
    FROM api.sign_in('boubou@teksol.info', 'monkeymonkey') AS r(result)
    CROSS JOIN LATERAL jwt_verify(r.result ->> 'token', current_setting('jwt.secret')) AS p;
  RESET ROLE;

  SET LOCAL ROLE TO anonymous;
    PREPARE p3 AS SELECT api.sign_in('asdfouasdo', 'monkeymonkey');
    SELECT throws_ok('p3', '28P01' /* invalid_password */, 'Invalid email or password', 'fails sign_in with wrong email');
  RESET ROLE;

  SET LOCAL ROLE TO anonymous;
    PREPARE p4 AS SELECT api.sign_in('boubou@teksol.info', 'invalid password');
    SELECT throws_ok('p4', '28P01' /* invalid_password */, 'Invalid email or password', 'fails sign_in with wrong password');
  RESET ROLE;

  SELECT * FROM finish();
ROLLBACK;
