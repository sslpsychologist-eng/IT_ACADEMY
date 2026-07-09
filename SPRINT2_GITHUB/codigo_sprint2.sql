/* =========================
   NIVELL 1 - EXERCICI 1
   ========================= */

DROP DATABASE IF EXISTS transactions;
DROP TABLE IF EXISTS company;
DROP TABLE IF EXISTS `transaction`;

-- Despues de ejecutar los scripts estructura_dades y dades_introduir:
USE transactions;
SHOW TABLES;
DESCRIBE company;
DESCRIBE `transaction`;


/* =========================
   NIVELL 1 - EXERCICI 2
   ========================= */

-- Exercici 2.1: Llistat dels paisos que estan generant vendes.
SELECT DISTINCT country
FROM company c
JOIN `transaction` t ON c.id = t.company_id
WHERE declined = 0;

-- Exercici 2.2: Des de quants paisos es generen les vendes?
SELECT COUNT(DISTINCT country) AS total_paisos
FROM company c
JOIN `transaction` t ON c.id = t.company_id
WHERE declined = 0;

-- Exercici 2.3: Identifica la companyia amb la mitjana mes gran de vendes.
SELECT mitjana_vendes_companyia.id,
       mitjana_vendes_companyia.company_name,
       max_mitjana_vendes.max_mitjana
FROM (
    SELECT c.id,
           c.company_name,
           ROUND(AVG(t.amount), 2) AS mitjana_vendes
    FROM company c
    JOIN `transaction` t ON c.id = t.company_id
    WHERE declined = 0
    GROUP BY c.id, c.company_name
) AS mitjana_vendes_companyia
JOIN (
    SELECT MAX(mitjana_vendes) AS max_mitjana
    FROM (
        SELECT c.id,
               c.company_name,
               ROUND(AVG(t.amount), 2) AS mitjana_vendes
        FROM company c
        JOIN `transaction` t ON c.id = t.company_id
        WHERE declined = 0
        GROUP BY c.id, c.company_name
    ) AS mitjana_vendes_companyia2
) AS max_mitjana_vendes
ON mitjana_vendes_companyia.mitjana_vendes = max_mitjana_vendes.max_mitjana;


/* =========================
   NIVELL 1 - EXERCICI 3: Utilitzant nomes subconsultes, sense JOIN
   ========================= */

-- 3.1 Mostra totes les transaccions realitzades per empreses d'Alemanya. ---> S'agafa com a realitzades totes les transaccions (completades i rebutjades "declined".
SELECT *
FROM `transaction` t
WHERE EXISTS (
    SELECT *
    FROM company c
    WHERE c.id = t.company_id
      AND c.country = 'Germany'
);

-- 3.2 Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT id, company_name
FROM company c
WHERE EXISTS (
    SELECT *
    FROM `transaction` t
    WHERE t.company_id = c.id
      AND t.amount > (
          SELECT AVG(amount) AS mitjana_transaccions
          FROM `transaction` t
      )
);

-- 3.3 Elimina del sistema les empreses que no tenen transaccions registrades.
SELECT *
FROM company c
WHERE NOT EXISTS (
    SELECT company_id
    FROM `transaction` t
    WHERE c.id = t.company_id
);


/* =========================
   NIVELL 1 - EXERCICI 4
   ========================= */

DROP TABLE IF EXISTS credit_card;

CREATE TABLE credit_card (
    id VARCHAR(100) PRIMARY KEY,
    iban VARCHAR(34),
    pan VARCHAR(25),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    expiring_date VARCHAR(8)
);

ALTER TABLE credit_card
MODIFY COLUMN id VARCHAR(15);

ALTER TABLE `transaction`
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);


/* =========================
   NIVELL 1 - EXERCICI 5
   ========================= */

SELECT *
FROM credit_card
WHERE id = 'CcU-2938';

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT *
FROM credit_card
WHERE id = 'CcU-2938';


/* =========================
   NIVELL 1 - EXERCICI 6
   ========================= */

INSERT INTO company (id)
VALUES ('b-9999');

INSERT INTO credit_card (id)
VALUES ('CcU-9999');

INSERT INTO `transaction` (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '829.999', '-117.999', '111.11', '0');

SELECT *
FROM `transaction`
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


/* =========================
   NIVELL 1 - EXERCICI 7
   ========================= */

SELECT *
FROM credit_card;

ALTER TABLE credit_card
DROP COLUMN pan;

SELECT *
FROM credit_card;


/* =========================
   NIVELL 1 - EXERCICI 8
   ========================= */

DROP DATABASE IF EXISTS nova_bd_transactions;
CREATE DATABASE nova_bd_transactions;
USE nova_bd_transactions;

DROP TABLE IF EXISTS companies;

CREATE TABLE companies (
    company_id VARCHAR(255) PRIMARY KEY,
    company_name VARCHAR(255) NULL,
    phone VARCHAR(255) NULL,
    email VARCHAR(255) NULL,
    country VARCHAR(255) NULL,
    website VARCHAR(255) NULL,
    merchant_category VARCHAR(255) NULL,
    merchant_price_position VARCHAR(255) NULL
);

DROP TABLE IF EXISTS credit_cards;

CREATE TABLE credit_cards (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NULL,
    iban VARCHAR(255) NULL,
    pan VARCHAR(255) NULL,
    pin VARCHAR(255) NULL,
    cvv VARCHAR(255) NULL,
    track1 VARCHAR(255) NULL,
    track2 VARCHAR(255) NULL,
    expiring_date VARCHAR(255) NULL,
    card_type VARCHAR(255) NULL,
    card_renewal_flag VARCHAR(255) NULL
);

DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
    id VARCHAR(255) PRIMARY KEY,
    card_id VARCHAR(255) NULL,
    business_id VARCHAR(255) NULL,
    timestamp VARCHAR(255) NULL,
    amount VARCHAR(255) NULL,
    declined VARCHAR(255) NULL,
    product_ids VARCHAR(255) NULL,
    user_id VARCHAR(255) NULL,
    lat VARCHAR(255) NULL,
    longitude VARCHAR(255) NULL,
    discount_amount VARCHAR(255) NULL,
    tax_amount VARCHAR(255) NULL,
    shipping_amount VARCHAR(255) NULL,
    channel VARCHAR(255) NULL,
    campaign_id VARCHAR(255) NULL,
    device_type VARCHAR(255) NULL,
    is_international VARCHAR(255) NULL,
    decline_reason VARCHAR(255) NULL,
    distance_km VARCHAR(255) NULL
);

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NULL,
    surname VARCHAR(255) NULL,
    phone VARCHAR(255) NULL,
    email VARCHAR(255) NULL,
    birth_date VARCHAR(255) NULL,
    country VARCHAR(255) NULL,
    city VARCHAR(255) NULL,
    postal_code VARCHAR(255) NULL,
    address VARCHAR(255) NULL,
    signup_date VARCHAR(255) NULL,
    user_segment VARCHAR(255) NULL,
    income_band VARCHAR(255) NULL
);

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__european_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__american_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Comprovar que el valor existeix a la taula de fets per assignar FK.
SELECT transactions.user_id
FROM transactions
LEFT JOIN users
ON transactions.user_id = users.id
WHERE users.id IS NULL;

SELECT transactions.card_id
FROM transactions
LEFT JOIN credit_cards
ON transactions.card_id = credit_cards.id
WHERE credit_cards.id IS NULL;

SELECT transactions.business_id
FROM transactions
LEFT JOIN companies
ON transactions.business_id = companies.company_id
WHERE companies.company_id IS NULL;

-- Assignar FK.
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_users
FOREIGN KEY (user_id)
REFERENCES users(id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_credit_cards
FOREIGN KEY (card_id)
REFERENCES credit_cards(id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_companies
FOREIGN KEY (business_id)
REFERENCES companies(company_id);


/* =========================
   NIVELL 1 - EXERCICI 9
   ========================= */

SELECT *
FROM (
    SELECT u.id,
           COUNT(t.id) AS total_transaccions
    FROM transactions t
    JOIN users u ON t.user_id = u.id
    GROUP BY u.id
    HAVING total_transaccions > 80
) AS transaccions_usuari;


/* =========================
   NIVELL 1 - EXERCICI 10
   ========================= */

SELECT cc.iban,
       ROUND(AVG(t.amount), 2) AS mitjana_amount
FROM transactions t
JOIN credit_cards cc ON t.card_id = cc.id
JOIN companies c ON t.business_id = c.company_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban;


/* =========================
   NIVELL 2 - EXERCICI 1
   ========================= */

USE nova_bd_transactions;

SELECT DATE(timestamp) AS data_transaccio,
       ROUND(SUM(amount), 2) AS total_vendes
FROM transactions t
WHERE declined = 0
GROUP BY DATE(timestamp)
ORDER BY total_vendes DESC
LIMIT 5;


/* =========================
   NIVELL 2 - EXERCICI 2
   ========================= */

SELECT c.company_name,
       c.phone,
       c.country,
       DATE(t.timestamp) AS date,
       ROUND(t.amount, 2) AS amount
FROM companies c
JOIN transactions t ON c.company_id = t.business_id
WHERE t.amount BETWEEN 350 AND 400
  AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY t.amount DESC;


/* =========================
   NIVELL 2 - EXERCICI 3
   ========================= */

SELECT business_id,
       COUNT(id) AS total_transaccions,
       CASE
           WHEN COUNT(id) >= 400 THEN 'igual o mes de 400 transaccions'
           ELSE 'menys de 400 transaccions'
       END AS transaccions_llindar400
FROM transactions
GROUP BY business_id;


/* =========================
   NIVELL 2 - EXERCICI 4
   ========================= */

USE transactions;

DELETE FROM transaction
WHERE id = '00044FFE-B650-4DCF-85DE-C7EDEE1CAAD';


/* =========================
   NIVELL 2 - EXERCICI 5
   ========================= */

DROP VIEW IF EXISTS VistaMarketing;

CREATE VIEW VistaMarketing AS
SELECT c.company_name,
       c.phone,
       c.country,
       ROUND(AVG(amount), 2) AS mitjana_compra
FROM companies c
JOIN transactions t
ON c.company_id = t.business_id
WHERE declined = 0
GROUP BY c.company_name, c.phone, c.country;

SELECT *
FROM VistaMarketing
ORDER BY mitjana_compra DESC;


/* =========================
   NIVELL 3 - EXERCICI 1
   ========================= */

USE nova_bd_transactions;
DROP TABLE IF EXISTS estat_targetes;

CREATE TABLE estat_targetes AS
SELECT card_id,
       SUM(declined) AS total_declined,
       CASE
           WHEN SUM(declined) = 3 THEN 'inactiu'
           ELSE 'actiu'
       END AS estat_targeta
FROM (
    SELECT card_id,
           timestamp,
           declined,
           ROW_NUMBER() OVER (
               PARTITION BY card_id
               ORDER BY timestamp DESC
           ) AS rn
    FROM transactions
) AS rn_table
WHERE rn <= 3
GROUP BY card_id;

SELECT COUNT(card_id) AS total_targetes_actives
FROM estat_targetes
WHERE estat_targeta = 'actiu';


/* =========================
   NIVELL 3 - EXERCICI 2
   ========================= */

USE nova_bd_transactions;
DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id VARCHAR(255) PRIMARY KEY,
    product_name VARCHAR(255) NULL,
    price VARCHAR(255) NULL,
    colour VARCHAR(255) NULL,
    wheight VARCHAR(255) NULL,
    warehouse_id VARCHAR(255) NULL,
    category VARCHAR(255) NULL,
    brand VARCHAR(255) NULL,
    cost VARCHAR(255) NULL,
    launch_date VARCHAR(255) NULL
);

LOAD DATA
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Comprovar si product_ids pot ser FK.
SELECT t.product_ids
FROM transactions t
LEFT JOIN products p
ON t.product_ids = p.id
WHERE p.id IS NULL;

-- Crear taula intermitja per poder unir FK amb PK, separant els diferents product_ids.
DROP TABLE IF EXISTS transaction_products;

CREATE TABLE transaction_products (
    transaction_id VARCHAR(255),
    product_id VARCHAR(255),
    PRIMARY KEY (transaction_id, product_id)
);

INSERT INTO transaction_products (transaction_id, product_id)
SELECT transactions.id,
       jt_product_ids.product_id
FROM transactions
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(transactions.product_ids, ', ', '","'), '"]'),
    '$[*]' COLUMNS (product_id VARCHAR(255) PATH '$')
) AS jt_product_ids;

ALTER TABLE transaction_products
ADD CONSTRAINT fk_transaction_id
FOREIGN KEY (transaction_id)
REFERENCES transactions(id);

ALTER TABLE transaction_products
ADD CONSTRAINT fk_product_id
FOREIGN KEY (product_id)
REFERENCES products(id);

SELECT product_id,
       COUNT(transaction_id) AS total_vendes
FROM transaction_products
GROUP BY product_id;
