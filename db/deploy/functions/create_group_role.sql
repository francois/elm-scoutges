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

    -- Deliberately always create a role, even if that would create an error
    -- This function is a single step within the registration process. If new
    -- people could create their own user within the same group, this could
    -- become a security issue. Instead, the first person to sign up will
    -- have to invite all other people. In this way, new users will become
    -- part of the group fo the person who invited them.
    EXECUTE 'CREATE ROLE ' || quote_ident(group_name) || ' NOSUPERUSER NOCREATEDB NOCREATEROLE ' ||
              'INHERIT NOLOGIN NOREPLICATION NOBYPASSRLS ' ||
              'IN ROLE authenticated';
    EXECUTE 'GRANT ' || quote_ident(group_name) || ' TO postgrest';

    RETURN group_name;
  END
  $$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

  REVOKE ALL PRIVILEGES ON FUNCTION public.create_group_role(text) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION public.create_group_role(text) TO anonymous;

  -- migrator is a superuser, and can thus create new roles
  ALTER FUNCTION public.create_group_role(text) OWNER TO migrator;

COMMIT;

-- vim: expandtab shiftwidth=2
