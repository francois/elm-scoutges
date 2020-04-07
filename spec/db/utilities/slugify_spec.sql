\i spec/db/setup.sql

BEGIN;
  SELECT plan(11);

  SELECT is(slugify(have), want, quote_ident(have))
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
  ) t0(have, want);

  SELECT finish();
ROLLBACK;
