USE superstore_mateo;

WITH resumen AS (
    SELECT
        COUNT(*) AS registros,
        COUNT(row_id) - COUNT(DISTINCT row_id) AS filas_duplicadas,
        COUNT(DISTINCT order_id) AS ordenes_unicas,
        COUNT(DISTINCT customer_id) AS clientes_unicos,
        COUNT(CASE WHEN order_date IS NULL OR ship_date IS NULL THEN 1 END) AS fechas_faltantes_o_invalidas,
        COUNT(CASE WHEN sales <= 0 THEN 1 END) AS ventas_no_positivas,
        COUNT(CASE WHEN discount < 0 OR discount > 1 THEN 1 END) AS descuentos_fuera_de_rango,
        COUNT(CASE WHEN ship_date < order_date THEN 1 END) AS envios_anteriores,
        COUNT(CASE
            WHEN order_date IS NULL OR ship_date IS NULL OR ship_date < order_date THEN 1
        END) AS filas_con_problemas_de_fecha,
        CONCAT_WS(', ',
            CASE WHEN COUNT(row_id) < COUNT(*) THEN 'row_id' END,
            CASE WHEN COUNT(order_id) < COUNT(*) THEN 'order_id' END,
            CASE WHEN COUNT(order_date) < COUNT(*) THEN 'order_date' END,
            CASE WHEN COUNT(ship_date) < COUNT(*) THEN 'ship_date' END,
            CASE WHEN COUNT(ship_mode) < COUNT(*) THEN 'ship_mode' END,
            CASE WHEN COUNT(customer_id) < COUNT(*) THEN 'customer_id' END,
            CASE WHEN COUNT(customer_name) < COUNT(*) THEN 'customer_name' END,
            CASE WHEN COUNT(segment) < COUNT(*) THEN 'segment' END,
            CASE WHEN COUNT(country) < COUNT(*) THEN 'country' END,
            CASE WHEN COUNT(city) < COUNT(*) THEN 'city' END,
            CASE WHEN COUNT(state) < COUNT(*) THEN 'state' END,
            CASE WHEN COUNT(postal_code) < COUNT(*) THEN 'postal_code' END,
            CASE WHEN COUNT(region) < COUNT(*) THEN 'region' END,
            CASE WHEN COUNT(product_id) < COUNT(*) THEN 'product_id' END,
            CASE WHEN COUNT(category) < COUNT(*) THEN 'category' END,
            CASE WHEN COUNT(sub_category) < COUNT(*) THEN 'sub_category' END,
            CASE WHEN COUNT(product_name) < COUNT(*) THEN 'product_name' END,
            CASE WHEN COUNT(sales) < COUNT(*) THEN 'sales' END,
            CASE WHEN COUNT(quantity) < COUNT(*) THEN 'quantity' END,
            CASE WHEN COUNT(discount) < COUNT(*) THEN 'discount' END,
            CASE WHEN COUNT(profit) < COUNT(*) THEN 'profit' END
        ) AS campos_con_null
    FROM superstore_ventas
)
SELECT STACK(
    10,
    'Registros', CAST(registros AS STRING),
    'Filas duplicadas por Row ID', CAST(filas_duplicadas AS STRING),
    'Ordenes unicas', CAST(ordenes_unicas AS STRING),
    'Clientes unicos', CAST(clientes_unicos AS STRING),
    'Campos con NULL', CASE WHEN campos_con_null = '' THEN 'Ninguno' ELSE campos_con_null END,
    'Fechas faltantes o invalidas', CAST(fechas_faltantes_o_invalidas AS STRING),
    'Ventas iguales o inferiores a cero', CAST(ventas_no_positivas AS STRING),
    'Descuentos fuera de [0, 1]', CAST(descuentos_fuera_de_rango AS STRING),
    'Envios anteriores al pedido', CAST(envios_anteriores AS STRING),
    'Filas con problemas de fecha', CAST(filas_con_problemas_de_fecha AS STRING)
) AS (indicador, resultado)
FROM resumen;
