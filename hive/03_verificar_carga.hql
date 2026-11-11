USE superstore_mateo;

SELECT COUNT(*) AS registros_csv FROM superstore_raw;

SELECT
    COUNT(*) AS registros_orc,
    COUNT(order_date) AS fechas_pedido_convertidas,
    COUNT(ship_date) AS fechas_envio_convertidas,
    COUNT(sales) AS ventas_convertidas
FROM superstore_ventas;

SELECT row_id, order_date, ship_date, product_name, sales
FROM superstore_ventas
WHERE row_id IN (1, 2, 3, 4, 5)
ORDER BY row_id;
