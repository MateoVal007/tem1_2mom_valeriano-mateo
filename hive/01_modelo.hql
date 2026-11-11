CREATE DATABASE IF NOT EXISTS superstore_mateo;
USE superstore_mateo;

CREATE EXTERNAL TABLE IF NOT EXISTS superstore_raw (
    row_id STRING,
    order_id STRING,
    order_date STRING,
    ship_date STRING,
    ship_mode STRING,
    customer_id STRING,
    customer_name STRING,
    segment STRING,
    country STRING,
    city STRING,
    state STRING,
    postal_code STRING,
    region STRING,
    product_id STRING,
    category STRING,
    sub_category STRING,
    product_name STRING,
    sales STRING,
    quantity STRING,
    discount STRING,
    profit STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE
LOCATION '/exam_superstore_mateo/raw'
TBLPROPERTIES ('skip.header.line.count' = '1');

CREATE TABLE IF NOT EXISTS superstore_ventas (
    row_id INT,
    order_id STRING,
    order_date DATE,
    ship_date DATE,
    ship_mode STRING,
    customer_id STRING,
    customer_name STRING,
    segment STRING,
    country STRING,
    city STRING,
    state STRING,
    postal_code STRING,
    region STRING,
    product_id STRING,
    category STRING,
    sub_category STRING,
    product_name STRING,
    sales DECIMAL(18,4),
    quantity INT,
    discount DECIMAL(5,4),
    profit DECIMAL(18,4)
)
STORED AS ORC;
