USE superstore_mateo;

-- La tabla temporal permite consultar el detalle y el resumen en la misma sesión.
CREATE TEMPORARY TABLE rfm_clientes_p4
STORED AS ORC
AS
WITH referencia AS (
    SELECT MAX(order_date) AS fecha_referencia
    FROM superstore_ventas
),
compras AS (
    SELECT
        customer_id,
        MAX(order_date) AS ultima_compra,
        COUNT(DISTINCT order_id) AS frecuencia,
        SUM(sales) AS monto
    FROM superstore_ventas
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
metricas AS (
    SELECT
        compras.*,
        referencia.fecha_referencia,
        DATEDIFF(referencia.fecha_referencia, compras.ultima_compra) AS recencia
    FROM compras CROSS JOIN referencia
),
puntuaciones AS (
    SELECT
        metricas.*,
        NTILE(5) OVER (ORDER BY recencia DESC, customer_id) AS puntaje_r,
        NTILE(5) OVER (ORDER BY frecuencia, customer_id) AS puntaje_f,
        NTILE(5) OVER (ORDER BY monto, customer_id) AS puntaje_m
    FROM metricas
)
SELECT
    puntuaciones.*,
    CASE
        WHEN puntaje_r >= 4 AND puntaje_f >= 4 AND puntaje_m >= 4 THEN 'Alto valor'
        WHEN puntaje_r <= 2 AND puntaje_f >= 3 THEN 'En riesgo'
        WHEN puntaje_f >= 3 THEN 'Recurrente'
        ELSE 'Otros clientes'
    END AS segmento
FROM puntuaciones;

SELECT
    fecha_referencia,
    segmento,
    COUNT(*) AS clientes,
    ROUND(AVG(recencia), 2) AS dias_promedio,
    ROUND(AVG(frecuencia), 2) AS ordenes_promedio,
    ROUND(SUM(monto), 2) AS ventas
FROM rfm_clientes_p4
GROUP BY fecha_referencia, segmento
ORDER BY segmento;

WITH ejemplos AS (
    SELECT
        rfm_clientes_p4.*,
        ROW_NUMBER() OVER (PARTITION BY segmento ORDER BY monto DESC, customer_id) AS posicion
    FROM rfm_clientes_p4
)
SELECT
    segmento, customer_id, ultima_compra, recencia, frecuencia, ROUND(monto, 2) AS monto,
    puntaje_r, puntaje_f, puntaje_m
FROM ejemplos
WHERE posicion <= 2
ORDER BY segmento, posicion;
