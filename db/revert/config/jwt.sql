-- Revert scoutges-test:config/jwt from pg

SET client_min_messages TO 'warning';

BEGIN;

  ALTER DATABASE scoutges_test RESET "jwt.secret";
  ALTER DATABASE scoutges_test RESET "security.bf_strength";

COMMIT;

-- vim: expandtab shiftwidth=2
