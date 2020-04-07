\i spec/db/setup.sql

BEGIN;
  SELECT plan(1);

  INSERT INTO public.groups(name, pgrole, slug) VALUES ('10eme', 'authenticated', '10eme');
  INSERT INTO public.users(email, password, group_name, name, phone, pgrole) VALUES ('boubou@teksol.info', 'monkeymonkey', '10eme', '', '', 'authenticated');
  SELECT matches(password, '^\$2a\$' || right('00' || current_setting('security.bf_strength'), 2) || '\$', 'password was encrypted')
  FROM users
  WHERE email = 'boubou@teksol.info';

  SELECT finish();
ROLLBACK;
