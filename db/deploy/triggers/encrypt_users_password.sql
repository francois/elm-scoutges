-- Deploy scoutges:triggers/encrypt_users_password to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.encrypt_users_password() RETURNS trigger AS $$
  BEGIN
    IF TG_OP = 'INSERT' OR NEW.password <> OLD.password THEN
      NEW.password = crypt(NEW.password, gen_salt('bf', coalesce(current_setting('security.bf_strength', true), '15')::integer));
    END IF;

    RETURN NEW;
  END
  $$ LANGUAGE plpgsql;

  DROP TRIGGER IF EXISTS encrypt_users_password ON api.users;

  CREATE TRIGGER encrypt_users_password
  BEFORE INSERT OR UPDATE OF password
  ON api.users
  FOR EACH ROW
  EXECUTE FUNCTION public.encrypt_users_password();

COMMIT;

-- vim: expandtab shiftwidth=2
