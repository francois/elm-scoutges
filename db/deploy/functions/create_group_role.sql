-- Deploy scoutges:functions/create_group_role to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.create_group_role(group_name text) RETURNS text AS $$
  BEGIN
    IF group_name IS NULL THEN
      RAISE EXCEPTION USING errcode = 'not_null_violation', hint = 'Cannot create identifier with null name';
    END IF;

    IF length(group_name) = 0 OR length(group_name) > 63 THEN
      RAISE EXCEPTION USING errcode = 'check_violation', hint = 'Identifier too long, keep it below 64 characters';
    END IF;

    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE pg_roles.rolname = group_name) THEN
      EXECUTE 'CREATE ROLE ' || quote_ident(group_name) || ' NOSUPERUSER NOCREATEDB NOCREATEROLE ' ||
                'INHERIT NOLOGIN NOREPLICATION NOBYPASSRLS ' ||
                'IN ROLE authenticated';
    END IF;

    RETURN group_name;
  END
  $$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

  REVOKE ALL PRIVILEGES ON FUNCTION public.create_group_role(text) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION public.create_group_role(text) TO anonymous;

COMMIT;

-- vim: expandtab shiftwidth=2
