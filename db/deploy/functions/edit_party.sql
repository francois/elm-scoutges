-- Deploy scoutges:functions/edit_party to pg
-- requires: tables/parties
-- requires: tables/party_addresses

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TYPE public.simple_address AS (name text, address text);

  CREATE OR REPLACE FUNCTION api.edit_party(slug text) RETURNS json AS $$
    SELECT row_to_json(r)
    FROM (
      SELECT slug, parties.name, parties.kind, parties.created_at, parties.updated_at
        , case
          when pa.slug is null then array[]::json[]
          else                      array_agg(row_to_json(row(pa.name, pa.address)::simple_address))
          end addresses
      FROM api.parties
      FULL OUTER JOIN (SELECT party_slug slug, name, address FROM api.party_addresses WHERE party_slug = edit_party.slug) pa USING (slug)
      WHERE parties.slug = edit_party.slug
      GROUP BY parties.slug, pa.slug) r;
  $$ LANGUAGE sql STABLE;

COMMIT;

  -- vim: expandtab shiftwidth=2
