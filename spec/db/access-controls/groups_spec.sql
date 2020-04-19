\i spec/db/setup.sql

BEGIN;
  SELECT plan(9);
  SELECT lives_ok('SELECT api.purge()', 'purge all');

  SET LOCAL ROLE TO anonymous;
    PREPARE p1 AS SELECT api.register('president@101st.org', 'president', '101st', '', '');
    SELECT lives_ok('p1');
  RESET ROLE;

  SET LOCAL ROLE TO anonymous;
    PREPARE p2 AS
      SELECT api.register(
          'baden@teksol.info'
        , 'monkeymonkey'
        , '47th'
        , 'Lord Robert Stephenson Smyth Baden Powell of Gilwell'
        , '03928341233');
    SELECT lives_ok('p2');

    SELECT set_eq('SELECT name FROM public.groups', array['47th', '101st'], 'anonymous can read groups');
    UPDATE public.groups SET name = '47eme';
    SELECT set_eq('SELECT name FROM public.groups', array['47th', '101st'], 'anonymous was not able to change any group names');
  RESET ROLE;

  SET LOCAL ROLE TO "47th";
    SELECT set_eq('SELECT name FROM public.groups', array['47th'], 'authenticated can only see their own group');

    PREPARE p5 AS
      UPDATE public.groups
      SET name = '47ème', slug = 'patate';

    SELECT lives_ok('p5', 'authenticated can update name and slug');
  RESET ROLE;
  RESET "request.jwt.claim.role";

  SELECT set_eq('SELECT name FROM public.groups', array['47ème', '101st'], 'group could not rename other groups');
  SELECT set_eq('SELECT slug FROM public.groups', array['patate', '101st'], 'group could not change other group slugs');

  SELECT * FROM finish();
ROLLBACK;
