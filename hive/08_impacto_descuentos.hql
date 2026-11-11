USE superstore_mateo;

CREATE TEMPORARY TABLE descuentos_p6 STORED AS ORC AS
SELECT category, sub_category, sales, profit, discount,
    CASE
        WHEN discount = 0 THEN 1
        WHEN discount > 0 AND discount <= 0.20 THEN 2
        WHEN discount > 0.20 AND discount <= 0.50 THEN 3
        WHEN discount > 0.50 AND discount <= 1 THEN 4
    END AS rango
FROM superstore_ventas
WHERE discount BETWEEN 0 AND 1;

SELECT
    CASE rango WHEN 1 THEN 'Sin descuento' WHEN 2 THEN 'Bajo'
               WHEN 3 THEN 'Medio' WHEN 4 THEN 'Alto' END AS nivel,
    COUNT(*) AS registros,
    ROUND(SUM(sales), 2) AS ventas,
    ROUND(SUM(profit), 2) AS ganancia,
    ROUND(100 * SUM(profit) / SUM(sales), 2) AS margen_pct,
    COUNT(CASE WHEN profit < 0 THEN 1 END) AS registros_con_perdida,
    ROUND(100.0 * COUNT(CASE WHEN profit <= 0 THEN 1 END) / COUNT(*), 2) AS no_rentables_pct,
    ROUND(100 * AVG(discount), 2) AS descuento_promedio_pct
FROM descuentos_p6
GROUP BY rango
ORDER BY rango;

SELECT category, sub_category, COUNT(*) AS registros_alto_descuento,
    COUNT(CASE WHEN profit < 0 THEN 1 END) AS registros_con_perdida,
    ROUND(SUM(CASE WHEN profit < 0 THEN profit ELSE 0 END), 2) AS perdida_acumulada,
    ROUND(SUM(profit), 2) AS ganancia_neta
FROM descuentos_p6
WHERE rango = 4
GROUP BY category, sub_category GROUPING SETS ((category), (category, sub_category))
ORDER BY perdida_acumulada, category, sub_category;
