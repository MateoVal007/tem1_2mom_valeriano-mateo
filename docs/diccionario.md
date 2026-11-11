# Diccionario de datos de Superstore

Cada registro representa una línea de pedido. Una orden puede ocupar varias filas y un cliente puede aparecer en varias órdenes.

| Columna CSV | Columna Hive | Tipo Hive | Descripción y regla de validación |
| --- | --- | --- | --- |
| Row ID | row_id | INT | Identificador positivo y único de la fila. |
| Order ID | order_id | STRING | Identificador de la orden. Puede repetirse. |
| Order Date | order_date | DATE | Fecha de pedido. El CSV usa mes/día/año. |
| Ship Date | ship_date | DATE | Fecha de envío. Debe ser igual o posterior a la fecha de pedido. |
| Ship Mode | ship_mode | STRING | Modalidad de envío. |
| Customer ID | customer_id | STRING | Identificador del cliente. Puede repetirse. |
| Customer Name | customer_name | STRING | Nombre del cliente. |
| Segment | segment | STRING | Segmento comercial del cliente. |
| Country | country | STRING | País de destino. |
| City | city | STRING | Ciudad de destino. |
| State | state | STRING | Estado de destino. |
| Postal Code | postal_code | STRING | Código postal. El archivo tiene valores de cuatro y cinco caracteres. Se conserva el valor de origen. |
| Region | region | STRING | Región comercial. |
| Product ID | product_id | STRING | Identificador del producto. Puede repetirse. |
| Category | category | STRING | Categoría del producto. |
| Sub-Category | sub_category | STRING | Subcategoría del producto. |
| Product Name | product_name | STRING | Nombre del producto. Puede contener comas y comillas. |
| Sales | sales | DECIMAL(18,4) | Importe de venta. Se espera un valor mayor que cero. |
| Quantity | quantity | INT | Unidades vendidas. Se espera un entero positivo. |
| Discount | discount | DECIMAL(5,4) | Descuento expresado como fracción entre 0 y 1. |
| Profit | profit | DECIMAL(18,4) | Ganancia de la línea. Un valor negativo representa una pérdida. |

El archivo descargado estaba en Windows-1252 y la copia del repositorio está en UTF-8. Se verificaron 9.994 registros con 21 campos por registro, sin campos vacíos en el CSV. Hay 2.221 filas con comas dentro de campos y 811 con comillas como parte de algún valor. El separador debe interpretarse según las reglas de CSV antes de convertir los tipos. Las reglas de calidad de la tabla son criterios para la auditoría de Hive.
