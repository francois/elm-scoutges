\set quiet on
\timing off
\pset pager off
\encoding unicode
\pset format unaligned
\pset tuples_only on
\set on_error_stop off

-- Reconnect as postgrest, the normal user from which all queries start
-- This ensures that session_user is the correct user, and really tests
-- that all SET ROLE will behave as on production
\connect -reuse-previous=on - postgrest
