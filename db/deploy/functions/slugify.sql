-- Deploy scoutges:functions/slugify to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.slugify(str text) RETURNS text AS $$
    SELECT regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              trim(lower(unaccent(str))) /* remove initial and trailing spaces, normalize to lower case and replace accents with non-accented same characters */
              , '\s+', '-', 'g') /* replace runs of spaces with dashes */
            , '[()]', '', 'g') /* remove parenthesis everywhere */
          , '[^-_a-z0-9]+', '_', 'g') /* replace runs of non pure-ascii with underscores */
        , '^[^a-z0-9]+', '') /* remove first non-letter, non-digit */
      , '[^a-z0-9]+$', '') /* remove last non-letter, non-digit */;
  $$ LANGUAGE sql IMMUTABLE RETURNS NULL ON NULL INPUT LEAKPROOF;

  REVOKE ALL PRIVILEGES ON FUNCTION public.slugify(text) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION public.slugify(text) TO PUBLIC;

COMMIT;

-- vim: expandtab shiftwidth=2
