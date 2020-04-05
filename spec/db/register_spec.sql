\i spec/db/_helper.sql

BEGIN;
  SELECT plan(2);

  SELECT ok(p.valid, 'returns valid token from api.register')
  FROM api.register('boubou@teksol.info', 'monkeymonkey') AS r(result)
  CROSS JOIN LATERAL jwt_verify(r.result ->> 'token', current_setting('jwt.secret')) AS p;

  PREPARE p2 AS SELECT email, pguser FROM public.users;
  SELECT results_eq('p2', 'VALUES(''boubou@teksol.info'', ''authenticated'')', 'sets role to authenticated');

  SELECT finish();
ROLLBACK;
