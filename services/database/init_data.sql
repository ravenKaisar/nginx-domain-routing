DROP DATABASE IF EXISTS express;
CREATE DATABASE express;
USE express;
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  id INT NOT NULL AUTO_INCREMENT,
  name varchar(255) NULL,
  email varchar(255) NULL,
  PRIMARY KEY (id)
);
INSERT INTO customers (name, email)
VALUES('Shohidullah Kaisar', 'ravenkaisar@gmail.com'),
  ('Mafinar', 'mafinar@gmail.com'),
  ('Masnun', 'masnun@gmail.com');