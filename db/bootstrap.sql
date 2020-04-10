CREATE ROLE migrator SUPERUSER LOGIN;
CREATE ROLE anonymous NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE postgrest LOGIN PASSWORD 'supersecretpassword' IN ROLE anonymous, authenticated;

SET ROLE TO migrator;
  CREATE DATABASE scoutges_ENV;
RESET ROLE;
