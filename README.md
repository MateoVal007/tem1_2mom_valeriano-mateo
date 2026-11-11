# Análisis de ventas Superstore con Apache Hive

Proyecto individual del segundo momento de Tecnologías Emergentes I. El objetivo es modelar el dataset Sample Superstore en Hive, auditar su calidad y analizar ventas, clientes y rentabilidad.

## Dataset

`Sample - Superstore.csv` está en UTF-8 y usa comas como separador. Contiene 9.994 registros y una cabecera de 21 columnas. Este archivo se usará directamente para la ingesta en Apache Hive y HDFS del entorno Docker de las prácticas.

El [diccionario de datos](docs/diccionario.md) define los nombres, tipos Hive y reglas que servirán para la tabla analítica.

## Pregunta 1 · Modelo e ingesta

Arranca el entorno Docker de las prácticas con el servicio `master`, el metastore y los DataNodes de HDFS. Espera a que HDFS salga del modo seguro. Desde la raíz de este repositorio, ejecuta en PowerShell:

```powershell
$master = 'bigdata-docker-compose-master-1'
docker cp 'Sample - Superstore.csv' "${master}:/tmp/superstore.csv"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo copiar el CSV al contenedor' }
docker exec $master hdfs dfs -mkdir -p /exam_superstore_mateo/raw
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la carpeta en HDFS' }
docker exec $master hdfs dfs -put -f /tmp/superstore.csv /exam_superstore_mateo/raw/superstore.csv
if ($LASTEXITCODE -ne 0) { throw 'No se pudo cargar el CSV en HDFS' }

foreach ($script in '01_modelo.hql', '02_carga.hql', '03_verificar_carga.hql') {
    docker cp "hive/$script" "${master}:/tmp/$script"
    if ($LASTEXITCODE -ne 0) { throw "No se pudo copiar $script" }
    docker exec $master hive -S --hiveconf hive.cli.print.header=true -f "/tmp/$script"
    if ($LASTEXITCODE -ne 0) { throw "Falló $script" }
}
```

- [DDL](hive/01_modelo.hql). Crea `superstore_mateo.superstore_raw`, una tabla externa de texto que lee el CSV con `OpenCSVSerde` y omite la cabecera, y `superstore_mateo.superstore_ventas`, una tabla tipada en ORC.
- [Carga](hive/02_carga.hql). Convierte las fechas de mes/día/año y los campos numéricos. Si una fecha no coincide con el valor interpretado, se carga como `NULL` para su auditoría. `INSERT OVERWRITE` permite repetir la carga completa sin duplicar filas.
- [Verificación](hive/03_verificar_carga.hql). Compara los conteos de las tablas y muestra las primeras cinco líneas de pedido.

Hive reportó 9.994 registros en ambas tablas. Las 9.994 filas de la tabla ORC tienen fechas de pedido, fechas de envío y ventas convertidas. La comparación de la tabla externa con el CSV confirmó que coinciden los 209.874 valores de origen. [Salida de Hive](docs/evidencias/01_carga.txt) · [Captura de los resultados](docs/evidencias/01_carga.png)

## Pregunta 2 · Auditoría de calidad

Después de la carga, ejecuta estas dos líneas desde la raíz del repositorio en CMD:

```bat
docker cp hive/04_auditoria_calidad.hql bigdata-docker-compose-master-1:/tmp/04_auditoria_calidad.hql
docker exec bigdata-docker-compose-master-1 hive -S --hiveconf hive.cli.print.header=true -f /tmp/04_auditoria_calidad.hql
```

La [consulta de auditoría](hive/04_auditoria_calidad.hql) lee la tabla ORC creada por el DDL y poblada por el DML de la pregunta 1. Cuenta las filas duplicadas como apariciones adicionales de cada `row_id` no nulo. Revisa los NULL de las 21 columnas y cuenta por separado las filas con fechas faltantes o inválidas y las filas cuyo envío precede al pedido.

Hive contó 9.994 registros, 5.009 órdenes y 793 clientes. Ninguna columna contiene NULL y los demás controles reportaron cero incidencias. [Salida de Hive](docs/evidencias/02_auditoria.txt)

Si aparecen incidencias en una carga futura, se debe contrastar el registro con el CSV original. En duplicados idénticos, se puede conservar una sola fila. Si el mismo identificador corresponde a valores distintos, conviene revisar el origen antes de decidir cuál conservar. Las fechas, ventas y descuentos inválidos deben corregirse con el dato de origen o apartarse del análisis que dependa de ese campo hasta resolver el caso.

## Pregunta 3 · Evolución comercial por región

Desde la raíz del repositorio, ejecuta en CMD:

```bat
docker cp hive/05_evolucion_regional.hql bigdata-docker-compose-master-1:/tmp/05_evolucion_regional.hql
docker exec bigdata-docker-compose-master-1 hive -S --hiveconf hive.cli.print.header=true -f /tmp/05_evolucion_regional.hql
```

La [consulta regional](hive/05_evolucion_regional.hql) agrupa ventas y ganancias por región y año mediante una CTE. Usa `LAG()` para comparar con el año inmediatamente anterior y `RANK()` para ordenar los totales regionales. El margen es la ganancia dividida entre las ventas. La variación de ganancia usa el valor absoluto del año anterior como base para que una mejora desde una pérdida tenga signo positivo. La variación queda en NULL si falta un año comparable o la base es cero.

Entre 2014 y 2017, West lideró en ventas (725.457,82), ganancia (108.418,45) y margen (14,94 %). South registró las menores ventas (391.721,91), y Central obtuvo la menor ganancia (39.706,36) y el menor margen (7,92 %). [Salida de Hive](docs/evidencias/03_evolucion_regional.txt)

## Pregunta 4 · Segmentación de clientes RFM

Desde la raíz del repositorio, ejecuta en CMD:

```bat
docker cp hive/06_segmentacion_rfm.hql bigdata-docker-compose-master-1:/tmp/06_segmentacion_rfm.hql
docker exec bigdata-docker-compose-master-1 hive -S --hiveconf hive.cli.print.header=true -f /tmp/06_segmentacion_rfm.hql
```

La [consulta RFM](hive/06_segmentacion_rfm.hql) calcula por cliente los días desde su última compra hasta el último pedido del dataset, las órdenes distintas y las ventas acumuladas. `NTILE(5)` asigna puntuaciones de 1 a 5, donde 5 representa compras más recientes, más frecuentes o de mayor importe, según la métrica. El identificador de cliente resuelve los empates de forma reproducible. Dos clientes con el mismo valor pueden quedar en quintiles contiguos.

Los segmentos se aplican en este orden:

| Segmento | Criterio |
| --- | --- |
| Alto valor | R, F y M de al menos 4. Combina actividad reciente, frecuencia y gasto alto. |
| En riesgo | R de 1 o 2 y F de al menos 3. Identifica clientes frecuentes cuya última compra está entre las más antiguas. |
| Recurrente | F de al menos 3 y sin cumplir las condiciones anteriores. |
| Otros clientes | Los clientes restantes. |

El DDL `CREATE TEMPORARY TABLE … AS SELECT` materializa los puntajes en ORC durante la sesión. El script devuelve un resumen y dos ejemplos por segmento. Para ver los 793 clientes, se puede agregar `SELECT * FROM rfm_clientes_p4 ORDER BY customer_id;` al final del script.

Con fecha de referencia del 30 de diciembre de 2017, Hive clasificó 104 clientes de alto valor, 146 en riesgo, 225 recurrentes y 318 en otros clientes. Los clientes en riesgo llevaban 217,62 días sin comprar en promedio. Los recurrentes llevaban 48,60 días. [Salida de Hive](docs/evidencias/04_segmentacion_rfm.txt)
