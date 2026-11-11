USE superstore_mateo;

WITH anual AS (
    SELECT
        region,
        YEAR(order_date) AS anio,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancia
    FROM superstore_ventas
    WHERE order_date IS NOT NULL AND region IS NOT NULL
    GROUP BY region, YEAR(order_date)
),
historico AS (
    SELECT
        anual.*,
        LAG(anio) OVER (PARTITION BY region ORDER BY anio) AS anio_previo,
        LAG(ventas) OVER (PARTITION BY region ORDER BY anio) AS ventas_previas,
        LAG(ganancia) OVER (PARTITION BY region ORDER BY anio) AS ganancia_previa
    FROM anual
)
SELECT
    region,
    anio,
    ROUND(ventas, 2) AS ventas,
    ROUND(ganancia, 2) AS ganancia,
    CASE WHEN ventas <> 0 THEN ROUND(100 * ganancia / ventas, 2) END AS margen_pct,
    CASE WHEN anio_previo = anio - 1 AND ventas_previas <> 0
         THEN ROUND(100 * (ventas - ventas_previas) / ventas_previas, 2)
    END AS variacion_ventas_pct,
    CASE WHEN anio_previo = anio - 1 AND ganancia_previa <> 0
         THEN ROUND(100 * (ganancia - ganancia_previa) / ABS(ganancia_previa), 2)
    END AS variacion_ganancia_pct
FROM historico
ORDER BY region, anio;

WITH totales AS (
    SELECT region, SUM(sales) AS ventas, SUM(profit) AS ganancia
    FROM superstore_ventas
    WHERE order_date IS NOT NULL AND region IS NOT NULL
    GROUP BY region
)
SELECT
    RANK() OVER (ORDER BY ventas DESC) AS posicion_ventas,
    RANK() OVER (ORDER BY ganancia DESC) AS posicion_ganancia,
    region,
    ROUND(ventas, 2) AS ventas,
    ROUND(ganancia, 2) AS ganancia,
    CASE WHEN ventas <> 0 THEN ROUND(100 * ganancia / ventas, 2) END AS margen_pct
FROM totales
ORDER BY posicion_ventas, region;
