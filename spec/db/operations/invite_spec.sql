\i spec/db/setup.sql

BEGIN;
  SELECT plan(5);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  PREPARE p1 AS SELECT api.register('francois@teksol.info', 'monkeymonkey', '1er Drummondville', 'François', '888 222-3333');
  SELECT lives_ok('p1');

  -- Remove pollution from api.register() above for the specs below
  DELETE FROM public.que_jobs;

  SET LOCAL ROLE TO "1er Drummondville";
    PREPARE p2 AS SELECT api.invite('{dany@teksol.info,susan@teksol.info}'::text[]);
    SELECT lives_ok('p2', 'can invite new people');

    SELECT set_eq(
        'SELECT email FROM api.users WHERE group_name = ''1er Drummondville'''
      , array['dany@teksol.info', 'susan@teksol.info', 'francois@teksol.info']
      , 'new people were registered in group');
    SELECT is((SELECT count(*) FROM api.users), 3::bigint, 'no extra users were invited');
  RESET ROLE;

  SELECT finish();
ROLLBACK;
