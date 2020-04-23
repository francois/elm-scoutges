\i spec/db/setup.sql

BEGIN;
  SELECT plan(4);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SELECT set_eq('SELECT current_setting(''security.bf_strength'', true)::integer', array[4], 'security.bf_strength is low to make specs run rapidly');

  SET LOCAL ROLE TO anonymous;
    SELECT ok(p.valid, 'returns valid token from api.register')
    FROM api.register('boubou@teksol.info', 'monkeymonkey', '11ème Daveluyville', 'Francois', '888 111-2222') AS r(result)
    CROSS JOIN LATERAL jwt_verify(r.result ->> 'token', current_setting('jwt.secret')) AS p;
  RESET ROLE;

  SET LOCAL ROLE TO "11ème Daveluyville";
    PREPARE p2 AS
      SELECT users.email, users.name, users.phone, users.group_name
      FROM api.users
      JOIN api.groups ON group_name = groups.name;
    SELECT results_eq('p2'
      , 'VALUES(''boubou@teksol.info'', ''Francois'', ''888 111-2222'', ''11ème Daveluyville'')'
      , 'sets role to group name');
  RESET ROLE;

  SELECT finish();
ROLLBACK;
