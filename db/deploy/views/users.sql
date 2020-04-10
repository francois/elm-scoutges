-- Deploy scoutges:views/users to pg
-- requires: tables/users
-- requires: schemas/api

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE VIEW api.users AS
    SELECT
        users.name AS user_name
      , users.email AS user_email
      , users.phone AS user_phone
      , users.registered_at AS user_registered_at
      , groups.name AS group_name
    FROM public.users
    JOIN public.groups ON groups.name = users.group_name
    ORDER BY users.registered_at;

COMMIT;

-- vim: expandtab shiftwidth=2
