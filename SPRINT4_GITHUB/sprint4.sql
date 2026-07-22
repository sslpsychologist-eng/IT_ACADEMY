--------------- NIVELL 1 ---------------
-- EXERCICI 1 (sense executar)

SELECT *
FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean` t
JOIN `sprint3-analytics-soniashah.sprint3_silver.companies_clean`c
ON t.business_id = c.company_id
WHERE DATE(t.timestamp) = "2022-03-12" AND c.country = 'Germany';

-- EXERCICI 2
-- Pas 1

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_silver.transactions_recent`
AS
SELECT 
  * EXCEPT(timestamp),
  TIMESTAMP_SUB(
    CURRENT_TIMESTAMP(),
    INTERVAL CAST(RAND() * 50 AS INT64) DAY
  ) AS timestamp
FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean`;

-- Pas 2

CREATE OR REPLACE TABLE
  `sprint3-analytics-soniashah.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp)
CLUSTER BY business_id
AS
SELECT *
FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_recent`;

-- EXERCICI 3
-- Pas 1

SELECT *
FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_recent`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- Pas 2
SELECT *
FROM `sprint3-analytics-soniashah.sprint3_gold.fact_transactions_optimized`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- EXERCICI 4

CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-soniashah.sprint3_gold.mv_daily_sales`
AS
SELECT DATE(timestamp) AS dia, SUM(amount) AS vendes_totals
FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean`
WHERE declined = 0
GROUP BY dia;

------------------------- NIVELL 2 -------------------------------------

-- EXERCICI 1

WITH VIP_stats AS (
  SELECT 
  user_id, 
  ROUND(SUM(amount),2) AS total_despesa,
  COUNT(transaction_id) AS quantitat_transaccions,
  ROUND(AVG(amount),2) AS tiquet_mitja,
  ROUND(MAX(amount),2) AS compra_maxima
  FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean`
  WHERE declined = 0
  GROUP BY user_id
  HAVING total_despesa > 500
)
SELECT 
u.user_id,
CONCAT(u.name, ' ', u.surname) AS nom_complet,
u.email, 
v.quantitat_transaccions, 
v.tiquet_mitja, 
v.compra_maxima, 
v.total_despesa
FROM VIP_stats v
JOIN `sprint3-analytics-soniashah.sprint3_silver.users_combined` u
ON v.user_id = u.user_id
ORDER BY total_despesa DESC;

-- EXERCICI 2

WITH vendes_comparades AS (
SELECT 
  dia,
  ROUND(vendes_totals,2) AS vendes_avui,
  ROUND(LAG(vendes_totals) OVER (
    ORDER BY dia),2
    ) AS vendes_ahir,
FROM `sprint3-analytics-soniashah.sprint3_gold.mv_daily_sales`
)
SELECT
  dia,
  vendes_avui,
  vendes_ahir,
  ROUND(SAFE_DIVIDE(vendes_avui - vendes_ahir, vendes_ahir) * 100, 2) AS diff_percentual
FROM vendes_comparades
ORDER BY dia;

-- EXERCICI 3

SELECT
  dia,
  ROUND(vendes_totals,2) AS vendes_avui,
  ROUND(
      SUM(vendes_totals) OVER (
          PARTITION BY EXTRACT(YEAR FROM dia)
          ORDER BY dia
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ),2) AS vendes_acumulades
FROM `sprint3-analytics-soniashah.sprint3_gold.mv_daily_sales`
ORDER BY dia;

-- EXECICI 4

WITH tres_compres AS (
  SELECT 
    user_id,
    timestamp,
    amount,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY timestamp
    ) AS num_compra
  FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean`
  WHERE declined = 0
  QUALIFY num_compra <= 3
),
tiquet_mitja AS (
SELECT
  user_id,
  ROUND(AVG(amount),2) AS mitjana_3_primeres_compres
FROM tres_compres
GROUP BY user_id
)

SELECT 
u.user_id,
CONCAT(u.name, ' ', u.surname) AS nom_complet,
u.email,
DATE(tc.timestamp) AS data_tercera_compra,
tc.amount AS import_tercera_compra,
tm.mitjana_3_primeres_compres
FROM `sprint3-analytics-soniashah.sprint3_silver.users_combined` u
JOIN tres_compres tc
  ON u.user_id = tc.user_id
  AND tc.num_compra = 3
JOIN tiquet_mitja tm
  ON u.user_id = tm.user_id;

------------------ NIVELL 3 ----------------------------------
-- EXERCICI 1

CREATE OR REPLACE TABLE `sprint3-analytics-soniashah.sprint3_gold.dim_transaccions_flat`
AS
SELECT
  tc.transaction_id,
  tc.timestamp,
  tc.amount AS total_ticket,
  product_id AS product_sku,
  pc.name AS product_name,
  pc.price AS product_price
FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean` tc
CROSS JOIN UNNEST(tc.product_ids) AS product_id
JOIN `sprint3-analytics-soniashah.sprint3_silver.products_clean` pc
  ON product_id = pc.product_id
WHERE tc.declined = 0;

-- EXERCICI 2

SELECT
  product_sku,
  product_name,
  COUNT(product_sku) AS total_vendes
FROM `sprint3-analytics-soniashah.sprint3_gold.dim_transaccions_flat`
GROUP BY
  product_sku,
  product_name
ORDER BY total_vendes DESC
LIMIT 5;

-- EXERCICI 3

CREATE OR REPLACE FUNCTION `sprint3-analytics-soniashah.sprint3_gold.calculate_tax`(amount FLOAT64)
RETURNS FLOAT64
AS (
  amount * 1.21
);

CREATE OR REPLACE TABLE `sprint3-analytics-soniashah.sprint3_gold.dim_transaccions_flat`
AS
SELECT
  tc.transaction_id,
  tc.timestamp,
  tc.amount AS total_ticket,
  product_id AS product_sku,
  pc.name AS product_name,
  pc.price AS product_price,
  ROUND(`sprint3-analytics-soniashah.sprint3_gold.calculate_tax`(pc.price),2) AS product_price_tax_inc
FROM `sprint3-analytics-soniashah.sprint3_silver.transactions_clean` tc
CROSS JOIN UNNEST(tc.product_ids) AS product_id
JOIN `sprint3-analytics-soniashah.sprint3_silver.products_clean` pc
  ON product_id = pc.product_id
WHERE tc.declined = 0;
