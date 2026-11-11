USE superstore_mateo;

CREATE TEMPORARY TABLE pareto_p8 STORED AS ORC AS
WITH productos AS (
    SELECT product_id, MIN(product_name) AS nombre, SUM(sales) AS ventas, SUM(profit) AS ganancia
    FROM superstore_ventas
    WHERE product_id IS NOT NULL
    GROUP BY product_id
),
aportes AS (
    SELECT product_id, nombre, metrica, importe
    FROM productos
    LATERAL VIEW STACK(2, 'Ventas', ventas, 'Ganancia', ganancia) s AS metrica, importe
),
acumulados AS (
    SELECT aportes.*,
        ROW_NUMBER() OVER (PARTITION BY metrica ORDER BY importe DESC, product_id) AS puesto,
        SUM(importe) OVER (PARTITION BY metrica) AS total,
        SUM(importe) OVER (
            PARTITION BY metrica ORDER BY importe DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS acumulado
    FROM aportes
)
SELECT acumulados.*,
    MIN(CASE WHEN total > 0 AND acumulado >= total * 0.80 THEN puesto END)
        OVER (PARTITION BY metrica) AS corte_80
FROM acumulados;

SELECT metrica, COUNT(*) AS productos_totales, MAX(corte_80) AS productos_para_80,
    ROUND(100.0 * MAX(corte_80) / COUNT(*), 2) AS productos_pct,
    ROUND(MAX(CASE WHEN puesto = corte_80 THEN 100 * acumulado / total END), 2) AS aporte_pct_en_corte,
    ROUND(MAX(total), 2) AS total
FROM pareto_p8
GROUP BY metrica
ORDER BY metrica;

SELECT metrica, puesto, product_id, nombre, ROUND(importe, 2) AS importe,
    CASE WHEN total > 0 THEN ROUND(100 * importe / total, 2) END AS aporte_pct,
    CASE WHEN total > 0 THEN ROUND(100 * acumulado / total, 2) END AS aporte_acumulado_pct
FROM pareto_p8
WHERE puesto <= 5 OR puesto = corte_80
ORDER BY metrica, puesto;
