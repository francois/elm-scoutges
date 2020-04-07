\i spec/db/setup.sql

BEGIN;
  SELECT plan(5);

  PREPARE p1 AS SELECT api.register('francois@teksol.info', 'monkeymonkey', '1er Drummondville', 'François', '888 222-3333');
  SELECT lives_ok('p1');

  -- Remove pollution from api.register() above for the specs below
  DELETE FROM que_jobs;

  SET LOCAL ROLE TO "1er Drummondville";
    PREPARE p2 AS SELECT api.invite('{dany@teksol.info,susan@teksol.info}'::text[]);
    SELECT lives_ok('p2', 'can invite new people');
  RESET ROLE;

  SELECT set_eq('SELECT email FROM users WHERE group_name = ''1er Drummondville''', array['dany@teksol.info', 'susan@teksol.info', 'francois@teksol.info'], 'new people were registered in group');
  SELECT is((SELECT count(*) FROM users), 3::bigint, 'no extra users were invited');
  SELECT set_eq('SELECT job_class || ''='' || args::text FROM public.que_jobs', array['Scoutges::Jobs::SendInvitedEmail=["dany@teksol.info"]', 'Scoutges::Jobs::SendInvitedEmail=["susan@teksol.info"]'], 'invited emails are queued');

  SELECT finish();
ROLLBACK;
