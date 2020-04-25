-- Deploy scoutges:grants/users to pg
-- requires: tables/users

SET client_min_messages TO 'warning';

BEGIN;

  REVOKE ALL PRIVILEGES ON TABLE api.users FROM PUBLIC;

  GRANT
      SELECT(email, password, name, phone, group_name, registered_at, slug)
    , INSERT(email, password, name, phone, group_name)
    , UPDATE(email, password, name, phone)
    , DELETE
  ON api.users TO authenticated;

  GRANT USAGE ON SEQUENCE api.users_id_seq TO authenticated;

  GRANT
      SELECT(pgrole, email, password, name, phone, group_name, registered_at)
  ON api.users TO privileged;

COMMIT;

-- vim: expandtab shiftwidth=2
