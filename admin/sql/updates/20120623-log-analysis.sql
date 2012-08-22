\set ON_ERROR_STOP 1
BEGIN;

CREATE TABLE log_statistic
(
    id                  SERIAL, -- PK
    timestamp           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    category            TEXT NOT NULL,
    data                TEXT NOT NULL -- JSON data
);

ALTER TABLE log_statistic ADD CONSTRAINT log_statistic_pkey PRIMARY KEY (id);

COMMIT;