\i spec/db/_helper.sql
\set on_error_stop on

BEGIN;
  SET client_min_messages TO warning;
  CREATE EXTENSION IF NOT EXISTS pgtap;

  ALTER DATABASE scoutges_test SET "jwt.secret" TO 'simple-string';

  -- Don't wait an eternity for encryption to proceed: during tests,
  -- it's perfectly fine to have a low-level of encryption
  ALTER DATABASE scoutges_test SET "security.bf_strength" TO '4';
COMMIT;
