USE superstore_mateo;

CREATE TEMPORARY TABLE ranking_productos_p5
STORED AS ORC
AS
WITH productos AS (
    SELECT
        category,
        product_id,
        MIN(product_name) AS nombre,
        SUM(quantity) AS unidades,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancia
    FROM superstore_ventas
    WHERE product_id IS NOT NULL AND category IS NOT NULL
    GROUP BY category, product_id
),
margenes AS (
    SELECT
        productos.*,
        CASE WHEN ventas > 0 THEN 100 * ganancia / ventas END AS margen_pct
    FROM productos
)
SELECT
    margenes.*,
    RANK() OVER (PARTITION BY category ORDER BY ganancia DESC) AS puesto_categoria,
    ROW_NUMBER() OVER (
        PARTITION BY category ORDER BY ganancia DESC, product_id
    ) AS orden_categoria,
    DENSE_RANK() OVER (ORDER BY unidades DESC) AS puesto_volumen,
    CASE WHEN margen_pct IS NOT NULL
         THEN RANK() OVER (
             ORDER BY CASE WHEN margen_pct IS NULL THEN 1 ELSE 0 END, margen_pct
         )
    END AS puesto_menor_margen,
    SUM(ganancia) OVER (
        PARTITION BY category ORDER BY ganancia DESC, product_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ganancia_acum_categoria
FROM margenes;

SELECT
    category, puesto_categoria AS puesto, product_id, nombre,
    ROUND(ganancia, 2) AS ganancia, ROUND(margen_pct, 2) AS margen_pct,
    ROUND(ganancia_acum_categoria, 2) AS ganancia_acumulada
FROM ranking_productos_p5
WHERE orden_categoria <= 5
ORDER BY category, puesto_categoria, product_id;

SELECT
    puesto_volumen AS puesto, product_id, nombre, unidades,
    ROUND(ventas, 2) AS ventas, ROUND(margen_pct, 2) AS margen_pct
FROM ranking_productos_p5
ORDER BY puesto_volumen, product_id
LIMIT 5;

SELECT
    puesto_menor_margen AS puesto, product_id, nombre,
    ROUND(ganancia, 2) AS ganancia, ROUND(margen_pct, 2) AS margen_pct
FROM ranking_productos_p5
WHERE puesto_menor_margen IS NOT NULL
ORDER BY puesto_menor_margen, product_id
LIMIT 5;
