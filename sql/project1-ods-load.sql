USE olist;

TRUNCATE TABLE ods_customers;
LOAD DATA LOCAL INFILE '/data/olist/olist_customers_dataset.csv'
INTO TABLE ods_customers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

TRUNCATE TABLE ods_geolocation;
LOAD DATA LOCAL INFILE '/data/olist/olist_geolocation_dataset.csv'
INTO TABLE ods_geolocation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

TRUNCATE TABLE ods_order_items;
LOAD DATA LOCAL INFILE '/data/olist/olist_order_items_dataset.csv'
INTO TABLE ods_order_items CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

TRUNCATE TABLE ods_order_payments;
LOAD DATA LOCAL INFILE '/data/olist/olist_order_payments_dataset.csv'
INTO TABLE ods_order_payments CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

TRUNCATE TABLE ods_orders;
LOAD DATA LOCAL INFILE '/data/olist/olist_orders_dataset.csv'
INTO TABLE ods_orders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

TRUNCATE TABLE ods_products;
LOAD DATA LOCAL INFILE '/data/olist/olist_products_dataset.csv'
INTO TABLE ods_products CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

TRUNCATE TABLE ods_sellers;
LOAD DATA LOCAL INFILE '/data/olist/olist_sellers_dataset.csv'
INTO TABLE ods_sellers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

TRUNCATE TABLE ods_category_translation;
LOAD DATA LOCAL INFILE '/data/olist/product_category_name_translation.csv'
INTO TABLE ods_category_translation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

SELECT 'ods_customers' AS tbl, COUNT(*) AS rows_loaded FROM ods_customers
UNION ALL SELECT 'ods_geolocation', COUNT(*) FROM ods_geolocation
UNION ALL SELECT 'ods_order_items', COUNT(*) FROM ods_order_items
UNION ALL SELECT 'ods_order_payments', COUNT(*) FROM ods_order_payments
UNION ALL SELECT 'ods_orders', COUNT(*) FROM ods_orders
UNION ALL SELECT 'ods_products', COUNT(*) FROM ods_products
UNION ALL SELECT 'ods_sellers', COUNT(*) FROM ods_sellers
UNION ALL SELECT 'ods_category_translation', COUNT(*) FROM ods_category_translation
UNION ALL SELECT 'ods_order_reviews', COUNT(*) FROM ods_order_reviews;
