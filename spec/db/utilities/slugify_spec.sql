\i spec/db/setup.sql

BEGIN;
  SELECT plan(11);

  SELECT is(slugify(str), want)
  FROM (VALUES
      ('10th', '10th')
    , ('10 eme', '10-eme')
    , ('10  eme', '10-eme')
    , ('   10   eme   ', '10-eme')
    , ('éabce/', 'eabce')
    , ('aébc/e', 'aebc_e')
    , ('_', '')
    , ('-', '')
    , (' ', '')
    , ('AbCd', 'abcd')
    , ('10ème Groupe Scout Est-Calade (Fleurimont)', '10eme-groupe-scout-est-calade-fleurimont')
  ) t0(str, want);

  SELECT finish();
ROLLBACK;
