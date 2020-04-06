-- Deploy scoutges:constraints/enforce_existence_of_users_pguser to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.check_role_exists() RETURNS trigger AS $$
  BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE pg_roles.rolname = NEW.pgrole) THEN
      RAISE foreign_key_violation USING message = 'Unknown database role: ' || NEW.pgrole;
      RETURN NULL;
    END IF;

    RETURN NEW;
  END
  $$ LANGUAGE plpgsql;

  DROP TRIGGER IF EXISTS check_role_exists ON public.groups;
  CREATE CONSTRAINT TRIGGER check_role_exists
  AFTER INSERT OR UPDATE OF pgrole
  ON public.groups
  FOR EACH ROW
  EXECUTE FUNCTION public.check_role_exists();


COMMIT;

-- vim: expandtab shiftwidth=2
