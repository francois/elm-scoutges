-- Deploy scoutges-test:config/jwt to pg

SET client_min_messages TO 'warning';

BEGIN;

  ALTER DATABASE scoutges_test SET "jwt.secret" TO 'simple-string';

  -- Don't wait an eternity for encryption to proceed: during tests,
  -- it's perfectly fine to have a low-level of encryption
  ALTER DATABASE scoutges_test SET "security.bf_strength" TO '4';

COMMIT;

-- vim: expandtab shiftwidth=2
