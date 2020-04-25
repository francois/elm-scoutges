-- Deploy scoutges:functions/edit_party to pg
-- requires: tables/parties
-- requires: tables/party_addresses

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION api.edit_party(slug text) RETURNS json AS $$
    SELECT row_to_json(r)
    FROM (
      SELECT parties.slug, parties.name, parties.kind, case when pa.slug is null then array[]::json[] else array_agg(row_to_json(pa)) end addresses
      FROM api.parties
      LEFT JOIN (SELECT party_slug slug, name, address FROM api.party_addresses) pa USING(slug)
      WHERE parties.slug = edit_party.slug
      GROUP BY slug, pa.slug) r
  $$ LANGUAGE sql STABLE;

COMMIT;

  -- vim: expandtab shiftwidth=2
