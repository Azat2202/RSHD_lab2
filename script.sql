CREATE TABLE if not exists test_table1 (
                             id SERIAL PRIMARY KEY,
                             data TEXT
) TABLESPACE cje38;

CREATE TABLE if not exists test_table2 (
                             id SERIAL PRIMARY KEY,
                             data TEXT
) TABLESPACE qdx64;

INSERT INTO test_table1 (data) VALUES ('Test data 1'), ('Test data 2');
INSERT INTO test_table2 (data) VALUES ('Test data 3'), ('Test data 4');



CREATE TEMP TABLE if not exists test_temp_table1 (
                             id SERIAL PRIMARY KEY,
                             data TEXT
) TABLESPACE cje38;

CREATE TEMP TABLE if not exists test_temp_table2 (
                             id SERIAL PRIMARY KEY,
                             data TEXT
) TABLESPACE qdx64;

INSERT INTO test_temp_table1 (data) VALUES ('Test data 1'), ('Test data 2');
INSERT INTO test_temp_table2 (data) VALUES ('Test data 3'), ('Test data 4');