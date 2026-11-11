USE superstore_mateo;

CREATE TEMPORARY TABLE tendencias_p7 STORED AS ORC AS
WITH mensual AS (
    SELECT TRUNC(order_date, 'MM') AS mes, SUM(sales) AS ventas, SUM(profit) AS ganancia
    FROM superstore_ventas
    WHERE order_date IS NOT NULL
    GROUP BY TRUNC(order_date, 'MM')
),
historico AS (
    SELECT mensual.*,
        LAG(mes) OVER (ORDER BY mes) AS mes_previo,
        LAG(ventas) OVER (ORDER BY mes) AS ventas_previas,
        LAG(ganancia) OVER (ORDER BY mes) AS ganancia_previa,
        LAG(mes, 2) OVER (ORDER BY mes) AS mes_dos_atras,
        AVG(ventas) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS promedio_ventas,
        AVG(ganancia) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS promedio_ganancia
    FROM mensual
)
SELECT h.mes, h.ventas, h.ganancia,
    CASE WHEN h.mes_previo = ADD_MONTHS(h.mes, -1) AND h.ventas_previas <> 0
         THEN 100 * (h.ventas - h.ventas_previas) / ABS(h.ventas_previas) END AS ventas_mensual_pct,
    CASE WHEN h.mes_previo = ADD_MONTHS(h.mes, -1) AND h.ganancia_previa <> 0
         THEN 100 * (h.ganancia - h.ganancia_previa) / ABS(h.ganancia_previa) END AS ganancia_mensual_pct,
    CASE WHEN a.ventas <> 0 THEN 100 * (h.ventas - a.ventas) / ABS(a.ventas) END AS ventas_anual_pct,
    CASE WHEN a.ganancia <> 0 THEN 100 * (h.ganancia - a.ganancia) / ABS(a.ganancia) END AS ganancia_anual_pct,
    CASE WHEN h.mes_dos_atras = ADD_MONTHS(h.mes, -2) THEN h.promedio_ventas END AS promedio_ventas_3m,
    CASE WHEN h.mes_dos_atras = ADD_MONTHS(h.mes, -2) THEN h.promedio_ganancia END AS promedio_ganancia_3m,
    ROW_NUMBER() OVER (ORDER BY h.ventas DESC, h.mes) AS mayor_venta,
    ROW_NUMBER() OVER (ORDER BY h.ventas, h.mes) AS menor_venta
FROM historico h
LEFT JOIN mensual a ON a.mes = ADD_MONTHS(h.mes, -12);

SELECT mes, ROUND(ventas, 2) AS ventas, ROUND(ganancia, 2) AS ganancia,
    ROUND(ventas_mensual_pct, 2) AS ventas_mensual_pct,
    ROUND(ganancia_mensual_pct, 2) AS ganancia_mensual_pct,
    ROUND(ventas_anual_pct, 2) AS ventas_anual_pct,
    ROUND(ganancia_anual_pct, 2) AS ganancia_anual_pct,
    ROUND(promedio_ventas_3m, 2) AS promedio_ventas_3m,
    ROUND(promedio_ganancia_3m, 2) AS promedio_ganancia_3m
FROM tendencias_p7
ORDER BY mes;

SELECT 'Mayor venta' AS grupo, mayor_venta AS puesto, mes, ROUND(ventas, 2) AS ventas
FROM tendencias_p7 WHERE mayor_venta <= 3
UNION ALL
SELECT 'Menor venta', menor_venta, mes, ROUND(ventas, 2)
FROM tendencias_p7 WHERE menor_venta <= 3
ORDER BY grupo, puesto;
