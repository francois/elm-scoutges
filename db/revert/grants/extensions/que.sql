-- Revert scoutges:grants/extensions/que from pg

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE que_jobs FROM postgrest, authenticated, anonymous;
  REVOKE EXECUTE ON FUNCTION que_validate_tags(jsonb), que_determine_job_state(public.que_jobs) FROM postgrest;

COMMIT;

-- vim: expandtab shiftwidth=2
