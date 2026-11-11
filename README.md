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
