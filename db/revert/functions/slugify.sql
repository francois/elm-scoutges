-- Revert scoutges:functions/slugify from pg

SET client_min_messages TO 'warning';

BEGIN;

  DROP FUNCTION public.slugify(text);

COMMIT;

-- vim: expandtab shiftwidth=2
