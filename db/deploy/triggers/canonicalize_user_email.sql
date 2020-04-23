-- Deploy scoutges:triggers/canonicalize_user_email to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.canonicalize_user_email() RETURNS trigger AS $$
  BEGIN
    NEW.email = lower(NEW.email);
    RETURN NEW;
  END
  $$ LANGUAGE plpgsql;

  DROP TRIGGER IF EXISTS canonicalize_user_email ON api.users;
  CREATE TRIGGER canonicalize_user_email
  BEFORE INSERT OR UPDATE OF email
  ON api.users
  FOR EACH ROW
  EXECUTE FUNCTION public.canonicalize_user_email();

COMMIT;

-- vim: expandtab shiftwidth=2
