-- Deploy scoutges:casts/jwt_token_to_json to pg
-- requires: extensions/pgjwt

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION jwt_token_to_json(r jwt_token) RETURNS json AS $$
  BEGIN
    RETURN json_build_object('token', r.token);
  END
  $$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE RETURNS NULL ON NULL INPUT;

  -- Literally anyone can call this function: it has no security at all
  GRANT EXECUTE ON FUNCTION jwt_token_to_json TO PUBLIC;

  CREATE CAST (jwt_token as json) WITH FUNCTION public.jwt_token_to_json(jwt_token) AS ASSIGNMENT;

COMMIT;

-- vim: expandtab shiftwidth=2
