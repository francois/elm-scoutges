\i spec/db/_helper.sql

BEGIN;
  SELECT plan(7);

  PREPARE p1 AS SELECT create_group_role('; DROP TABLE groups; --');
  SELECT lives_ok('p1', 'can create little bobby tables group');

  SELECT lives_ok('SET LOCAL ROLE TO "; DROP TABLE groups; --"', 'can switch to bobby tables role');
  RESET ROLE;

  PREPARE p3 AS SELECT create_group_role(repeat('a', 63));
  SELECT lives_ok('p3', 'accepts identifiers up to 63 characters long');

  PREPARE p4 AS SELECT create_group_role(repeat('a', 64));
  SELECT throws_ok('p4', '23514' /* check_violation */, NULL, 'rejects identifiers 64 characters in length');

  PREPARE p5 AS SELECT create_group_role(repeat('a', 65));
  SELECT throws_ok('p5', '23514' /* check_violation */, NULL, 'rejects identifiers 65 characters in length');

  PREPARE p6 AS SELECT create_group_role('');
  SELECT throws_ok('p6', '23514' /* check_violation */, NULL, 'rejects empty identifier');

  PREPARE p7 AS SELECT create_group_role(null);
  SELECT throws_ok('p7', '23502' /* not_null_violation */, NULL, 'rejects null identifier');

  SELECT finish();
ROLLBACK;
