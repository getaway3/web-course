-- Предметная область варианта 1: Pet Clinic. Таблица питомцев.
DROP TABLE IF EXISTS pets;

CREATE TABLE pets (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    species VARCHAR(50)  NOT NULL,
    age     INTEGER      NOT NULL CHECK (age >= 0)
);
