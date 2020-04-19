\i spec/db/setup.sql

BEGIN;
  SELECT plan(3);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('carnival@teksol.info', 'somepassword', '10eme', '', '');
    SELECT lives_ok('p1');

    SELECT matches(password, '^\$2a\$' || right('00' || current_setting('security.bf_strength'), 2) || '\$', 'password was encrypted')
    FROM users
    WHERE email = 'carnival@teksol.info';
  RESET ROLE;

  SELECT finish();
ROLLBACK;
