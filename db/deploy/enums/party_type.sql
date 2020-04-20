-- Deploy scoutges:enums/party_type to pg

SET client_min_messages TO 'warning';

BEGIN;

  CREATE TYPE public.party_type AS ENUM ('customer', 'supplier', 'troop', 'group');

  COMMENT ON TYPE public.party_type IS 'Describes the relationship of the owning group towards that party';

COMMIT;

-- vim: expandtab shiftwidth=2
