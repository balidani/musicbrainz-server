BEGIN;
  CREATE SCHEMA statistics;
  ALTER TABLE statistic SET SCHEMA statistics;
  ALTER TABLE statistic_event SET SCHEMA statistics;
COMMIT;
