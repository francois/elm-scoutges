-- Deploy scoutges:functions/generate_serial_no to pg
-- requires: extensions/pgcrypto

SET client_min_messages TO 'warning';

BEGIN;

  CREATE OR REPLACE FUNCTION public.generate_serial_nos(n integer) RETURNS text AS $$
    SELECT array_to_string(array_agg(substring('0123456789abcdefghijklmnopqrstuvwxyz', (1 + 26 * random())::integer, 1)), '')
    FROM generate_series(1, n, 1) AS t0
  $$ LANGUAGE sql VOLATILE;

  COMMENT ON FUNCTION public.generate_serial_nos(integer) IS 'Generates a random serial number, N characters in length';
  REVOKE ALL PRIVILEGES ON FUNCTION public.generate_serial_nos(integer) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION public.generate_serial_nos(integer) TO authenticated;

  CREATE OR REPLACE FUNCTION public.generate_serial_nos() RETURNS text AS $$
    SELECT generate_serial_nos(5);
  $$ LANGUAGE sql VOLATILE;

  COMMENT ON FUNCTION public.generate_serial_nos() IS 'Generates a random serial number, 5 characters in length';
  REVOKE ALL PRIVILEGES ON FUNCTION public.generate_serial_nos() FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION public.generate_serial_nos() TO authenticated;

COMMIT;

-- vim: expandtab shiftwidth=2
