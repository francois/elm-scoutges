-- Deploy scoutges:extensions/pgjwt to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TYPE jwt_token AS (
    token text
  );

  -- Copied from https://raw.githubusercontent.com/michelp/pgjwt/a47d70287566097a8d8994065cedc91a289b5146/pgjwt--0.1.0.sql

  CREATE OR REPLACE FUNCTION public.jwt_url_encode(data bytea) RETURNS text LANGUAGE sql AS $$
      SELECT translate(encode(data, 'base64'), E'+/=\n', '-_');
  $$;


  CREATE OR REPLACE FUNCTION public.jwt_url_decode(data text) RETURNS bytea LANGUAGE sql AS $$
    WITH t AS (SELECT translate(data, '-_', '+/') AS trans),
       rem AS (SELECT length(t.trans) % 4 AS remainder FROM t) -- compute padding size
      SELECT decode(
          t.trans ||
          CASE WHEN rem.remainder > 0
             THEN repeat('=', (4 - rem.remainder))
             ELSE '' END,
      'base64') FROM t, rem;
  $$;


  CREATE OR REPLACE FUNCTION public.jwt_algorithm_sign(signables text, secret text, algorithm text)
  RETURNS text LANGUAGE sql AS $$
    WITH
      alg AS (
        SELECT CASE
          WHEN algorithm = 'HS256' THEN 'sha256'
          WHEN algorithm = 'HS384' THEN 'sha384'
          WHEN algorithm = 'HS512' THEN 'sha512'
          ELSE '' END AS id)  -- hmac throws error
    SELECT public.jwt_url_encode(public.hmac(signables, secret, alg.id)) FROM alg;
  $$;


  CREATE OR REPLACE FUNCTION public.jwt_sign(payload json, secret text, algorithm text DEFAULT 'HS256')
  RETURNS text LANGUAGE sql AS $$
  WITH
    header AS (
      SELECT public.jwt_url_encode(convert_to('{"alg":"' || algorithm || '","typ":"JWT"}', 'utf8')) AS data
      ),
    payload AS (
      SELECT public.jwt_url_encode(convert_to(payload::text, 'utf8')) AS data
      ),
    signables AS (
      SELECT header.data || '.' || payload.data AS data FROM header, payload
      )
  SELECT
      signables.data || '.' ||
      public.jwt_algorithm_sign(signables.data, secret, algorithm) FROM signables;
  $$;


  CREATE OR REPLACE FUNCTION public.jwt_verify(token text, secret text, algorithm text DEFAULT 'HS256')
  RETURNS table(header json, payload json, valid boolean) LANGUAGE sql AS $$
    SELECT
      convert_from(public.jwt_url_decode(r[1]), 'utf8')::json AS header,
      convert_from(public.jwt_url_decode(r[2]), 'utf8')::json AS payload,
      r[3] = public.jwt_algorithm_sign(r[1] || '.' || r[2], secret, algorithm) AS valid
    FROM regexp_split_to_array(token, '\.') r;
  $$;

COMMIT;

-- vim: expandtab shiftwidth=2
