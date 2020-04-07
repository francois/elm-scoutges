\i spec/db/setup.sql

BEGIN;
  SELECT plan(2);

  SELECT ok(p.valid, 'returns valid token from api.register')
  FROM api.register('boubou@teksol.info', 'monkeymonkey', '11ème Daveluyville', 'Francois', '888 111-2222') AS r(result)
  CROSS JOIN LATERAL jwt_verify(r.result ->> 'token', current_setting('jwt.secret')) AS p;

  PREPARE p2 AS
    SELECT users.email, users.name, users.phone, users.group_name, groups.pgrole
    FROM public.users
    JOIN public.groups ON group_name = groups.name;
  SELECT results_eq('p2'
    , 'VALUES(''boubou@teksol.info'', ''Francois'', ''888 111-2222'', ''11ème Daveluyville'', ''11ème Daveluyville'')'
    , 'sets role to group name');

  SELECT finish();
ROLLBACK;