-- Deploy scoutges:functions/save_full_party to pg
-- requires: tables/parties
-- requires: tables/party_addresses

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.save_full_party(rec json) RETURNS json AS $$
  DECLARE
    slug text;
  BEGIN
    IF rec ->> 'slug' IS NULL THEN
      INSERT INTO api.parties(name, kind, pgrole)
      VALUES(rec ->> 'name', (rec ->> 'kind')::party_kind, current_user)
      RETURNING parties.slug INTO slug;
    ELSE
      UPDATE api.parties
      SET name = rec ->> 'name', kind = (rec ->> 'kind')::party_kind
      WHERE parties.slug = rec ->> 'slug';
    END IF;

    RETURN '{}'::json;
  END
  $$ LANGUAGE plpgsql;

COMMIT;

-- vim: expandtab shiftwidth=2
