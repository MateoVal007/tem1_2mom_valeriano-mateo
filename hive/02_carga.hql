USE superstore_mateo;

WITH origen AS (
    SELECT
        raw.*,
        UNIX_TIMESTAMP(TRIM(order_date), 'M/d/yyyy') AS order_date_ts,
        UNIX_TIMESTAMP(TRIM(ship_date), 'M/d/yyyy') AS ship_date_ts
    FROM superstore_raw raw
)
INSERT OVERWRITE TABLE superstore_ventas
SELECT
    CAST(row_id AS INT) AS row_id,
    order_id,
    CASE
        WHEN FROM_UNIXTIME(order_date_ts, 'M/d/yyyy') =
             REGEXP_REPLACE(TRIM(order_date), '(^|/)0([0-9])(?=/)', '$1$2')
        THEN CAST(FROM_UNIXTIME(order_date_ts, 'yyyy-MM-dd') AS DATE)
    END AS order_date,
    CASE
        WHEN FROM_UNIXTIME(ship_date_ts, 'M/d/yyyy') =
             REGEXP_REPLACE(TRIM(ship_date), '(^|/)0([0-9])(?=/)', '$1$2')
        THEN CAST(FROM_UNIXTIME(ship_date_ts, 'yyyy-MM-dd') AS DATE)
    END AS ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    CAST(sales AS DECIMAL(18,4)) AS sales,
    CAST(quantity AS INT) AS quantity,
    CAST(discount AS DECIMAL(5,4)) AS discount,
    CAST(profit AS DECIMAL(18,4)) AS profit
FROM origen;
