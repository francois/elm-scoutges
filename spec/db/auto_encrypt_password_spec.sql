\i spec/db/_helper.sql

BEGIN;
  SELECT plan(1);

  INSERT INTO public.users(email, password, pguser) VALUES ('boubou@teksol.info', 'monkeymonkey', 'authenticated');
  SELECT matches(password, '^\$2a\$' || right('00' || current_setting('security.bf_strength'), 2) || '\$', 'password was encrypted')
  FROM users
  WHERE email = 'boubou@teksol.info';

  SELECT finish();
ROLLBACK;
