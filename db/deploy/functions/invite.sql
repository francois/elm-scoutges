-- Deploy scoutges:functions/invite to pg
-- requires: tables/users
-- requires: extensions/que

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.invite(emails text[]) RETURNS text AS $$
  DECLARE
    group_name text;
  BEGIN
    SELECT name
    INTO group_name
    FROM public.groups
    LIMIT 1;

    INSERT INTO public.users(email, password, name, group_name, phone)
      SELECT email, gen_random_uuid(), email, group_name, ''
      FROM unnest(emails) AS e(email);

    INSERT INTO public.que_jobs(job_class, args)
      SELECT 'Scoutges::Jobs::SendInvitedEmail', jsonb_build_array(email)
      FROM unnest(emails) AS e(email);

    RETURN NULL;
  END
  $$ LANGUAGE plpgsql;

  REVOKE ALL PRIVILEGES ON FUNCTION api.invite(text[]) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION api.invite(text[]) TO authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
