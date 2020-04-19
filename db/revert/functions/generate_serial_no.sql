-- Revert scoutges:functions/generate_serial_no from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.generate_serial_nos(integer);
  DROP FUNCTION public.generate_serial_nos();

COMMIT;

-- vim: expandtab shiftwidth=2
