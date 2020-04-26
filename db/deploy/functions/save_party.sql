-- Deploy scoutges:functions/save_party to pg
-- requires: tables/parties
-- requires: tables/party_addresses

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.save_party(rec json) RETURNS json AS $$
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
      WHERE parties.slug = rec ->> 'slug'
      RETURNING parties.slug INTO slug;
    END IF;

    DELETE FROM api.party_addresses
    WHERE party_slug = slug;

    INSERT INTO api.party_addresses(party_slug, name, address)
      SELECT slug, r.name, r.address
      FROM json_to_recordset(rec -> 'addresses') r(name text, address text)
      WHERE trim(coalesce(name, '')) <> ''
        AND trim(coalesce(address, '')) <> '';

    RETURN '{}'::json;
  END
  $$ LANGUAGE plpgsql;

COMMIT;

-- vim: expandtab shiftwidth=2
