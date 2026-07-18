--NIVELL 1

-- EXERCICI 1

CREATE SCHEMA `sprint3-analytics-soniashah.sprint3_silver`
OPTIONS (
  location = 'EU'
);

-- EXERCICI 2

CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';',
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-soniashah.sprint3_bronze.companies_raw` (
    company_id STRING,
    company_name STRING,
    phone STRING,
    email STRING,
    country STRING,
    website STRING
  )
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-soniashah.sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-soniashah.sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-soniashah.sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1
);

-- EXERCICI 3: No precisa codi SQL

-- EXERCICI 4

-- a) Materialització de Dades (Assistit per IA)

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw_native`
AS
SELECT *
FROM `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw`;

-- b) Auditoria de Costos
SELECT id
FROM `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw`;

SELECT id
FROM `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw_native`;

-- c) El perill del LIMIT
SELECT id
FROM `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw`
LIMIT 10;

SELECT id
FROM `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw_native`
LIMIT 10;

-- EXERCICI 5

SELECT
  DATE(timestamp) AS data_transaccio,
  ROUND(SUM(amount), 2) AS total_ingressos
FROM `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw_native`
WHERE EXTRACT(YEAR FROM timestamp) = 2021
  AND declined = 0
GROUP BY DATE(timestamp)
ORDER BY total_ingressos DESC
LIMIT 5;

-- EXERCICI 6

SELECT
  c.company_name,
  c.phone,
  c.country,
  DATE(t.timestamp) AS date,
  ROUND(t.amount, 2) AS amount
FROM `sprint3-analytics-soniashah.sprint3_bronze.companies_raw` AS c
JOIN `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw_native` AS t
  ON c.company_id = t.business_id
WHERE t.amount BETWEEN 100 AND 200
  AND DATE(t.timestamp) IN (
    DATE '2015-04-29',
    DATE '2018-07-20',
    DATE '2024-03-13'
  )
ORDER BY amount DESC;

-------------------------------NIVELL 2-----------------------------------------------

-- EXERCICI 1

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_silver.products_clean`
AS
SELECT
  id AS product_id,
  product_name AS name,
  SAFE_CAST(price AS FLOAT64) AS price,
  colour,
  weight,
  SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  category,
  brand,
  cost,
  launch_date
FROM `sprint3-analytics-soniashah.sprint3_bronze.products_raw`;

-- EXERCICI 2

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_silver.transactions_clean`
AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  timestamp,
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
  declined,
  ARRAY(
    SELECT CAST(TRIM(product_id) AS INT64)
    FROM UNNEST(SPLIT(product_ids, ',')) AS product_id
  ) AS product_ids,
  user_id,
  lat,
  longitude
FROM `sprint3-analytics-soniashah.sprint3_bronze.transactions_raw`;

-- EXERCICI 3

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_silver.users_combined`
AS
SELECT 
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'America' AS origin
FROM `sprint3-analytics-soniashah.sprint3_bronze.american_users_raw`
UNION ALL
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'Europe' AS origin
FROM `sprint3-analytics-soniashah.sprint3_bronze.european_users_raw`;

-- EXERCICI 4

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_silver.companies_clean`
AS
SELECT *
FROM `sprint3-analytics-soniashah.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_silver.credit_cards_clean`
AS
SELECT 
  id AS credit_cards_id,
  user_id,
  iban,
  pan,
  pin,
  cvv,
  track1,
  track2,
  expiring_date
FROM `sprint3-analytics-soniashah.sprint3_bronze.credit_cards_raw`;

---------------------------- NIVELL 3---------------------------------

-- EXERCICI 1

CREATE OR REPLACE VIEW `sprint3-analytics-soniashah.sprint3_gold.v_marketing_kpis` AS
SELECT c.company_name,
c.phone,
c.country,
ROUND(AVG(t.amount),2) AS mitjana_compra,
CASE
  WHEN AVG(t.amount) > 260 THEN 'Premium'
  ELSE 'Standard'
  END AS client_tier
FROM `sprint3-analytics-soniashah.sprint3_silver.companies_clean` c
JOIN `sprint3-analytics-soniashah.sprint3_silver.transactions_clean` t
  ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY c.company_id,
c.company_name,
c.phone,c.country;

SELECT *
FROM `sprint3-analytics-soniashah.sprint3_gold.v_marketing_kpis`
ORDER BY client_tier DESC, mitjana_compra DESC;

-- EXERCICI 2

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_gold.product_sales_ranking`
AS

SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour,
  COUNT(t_unnested.product_id_unnested) AS total_sold

FROM `sprint3-analytics-soniashah.sprint3_silver.products_clean` AS p

LEFT JOIN (
  SELECT
    product_id_unnested
  FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean` AS t
  CROSS JOIN UNNEST(t.product_ids) AS product_id_unnested
) AS t_unnested

ON p.product_id = t_unnested.product_id_unnested

GROUP BY
  p.product_id,
  p.name,
  p.price,
  p.colour

ORDER BY total_sold DESC;

-- EXERCICI 3

SELECT name, total_sold
FROM `sprint3-analytics-soniashah.sprint3_gold.product_sales_ranking`
ORDER BY total_sold DESC
LIMIT 10;