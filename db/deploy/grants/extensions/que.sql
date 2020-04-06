-- Deploy scoutges:grants/extensions/que to pg
-- requires: extensions/que

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE que_jobs, que_values FROM PUBLIC;

  GRANT INSERT ON TABLE que_jobs, que_values TO anonymous, authenticated, postgrest;
  GRANT INSERT ON TABLE que_lockers TO postgrest;
  GRANT SELECT, DELETE ON TABLE que_jobs, que_lockers TO postgrest;
  GRANT USAGE ON SEQUENCE que_jobs_id_seq TO anonymous, authenticated, postgrest;

  REVOKE ALL PRIVILEGES ON FUNCTION que_validate_tags(jsonb), que_determine_job_state(public.que_jobs) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION que_validate_tags(jsonb), que_determine_job_state(public.que_jobs) TO anonymous, authenticated, postgrest;

  GRANT SELECT ON TABLE que_lockers TO anonymous, authenticated, postgrest;
COMMIT;

-- vim: expandtab shiftwidth=2
