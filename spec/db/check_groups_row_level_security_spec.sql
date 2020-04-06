\i spec/db/_helper.sql

BEGIN;

  SELECT plan(7);

  CREATE ROLE "101st" WITH NOLOGIN IN ROLE authenticated;
  INSERT INTO public.groups(name, pgrole, slug) VALUES ('101st', 'authenticated', '101st');

  SET LOCAL ROLE TO anonymous;
    -- Required to mimic what PostgREST does
    SET LOCAL "request.jwt.claim.role" TO 'anonymous';

    PREPARE p1 AS
      SELECT api.register(
          'baden@teksol.info'
        , 'monkeymonkey'
        , '47th'
        , 'Lord Robert Stephenson Smyth Baden Powell of Gilwell'
        , '03928341233');
    SELECT lives_ok('p1');

    SELECT lives_ok('SELECT name FROM public.groups', 'anonymous can read groups');
    SELECT throws_ok('UPDATE public.groups SET name = ''47eme''', '42501', NULL, 'anonymous cannot update group names');
  RESET ROLE;

  SET LOCAL ROLE TO "47th";
    SET LOCAL "request.jwt.claim.role" TO '47th';
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
