SELECT tbl, cand_key, rows_n, uniq_n, rows_n - uniq_n AS dup_rows,
       IF(rows_n = uniq_n, 'OK', 'NOT A KEY') AS verdict
FROM (
            SELECT 'ods_orders'               AS tbl, 'order_id'                     AS cand_key, COUNT(*) AS rows_n, COUNT(DISTINCT order_id) AS uniq_n FROM ods_orders
  UNION ALL SELECT 'ods_order_items',                'order_id+order_item_id',                  COUNT(*), COUNT(DISTINCT order_id, order_item_id)               FROM ods_order_items
  UNION ALL SELECT 'ods_order_payments',             'order_id+payment_sequential',             COUNT(*), COUNT(DISTINCT order_id, payment_sequential)          FROM ods_order_payments
  UNION ALL SELECT 'ods_order_reviews',              'review_id+order_id',                      COUNT(*), COUNT(DISTINCT review_id, order_id)                   FROM ods_order_reviews
  UNION ALL SELECT 'ods_customers',                  'customer_id',                             COUNT(*), COUNT(DISTINCT customer_id)                           FROM ods_customers
  UNION ALL SELECT 'ods_products',                   'product_id',                              COUNT(*), COUNT(DISTINCT product_id)                            FROM ods_products
  UNION ALL SELECT 'ods_sellers',                    'seller_id',                               COUNT(*), COUNT(DISTINCT seller_id)                             FROM ods_sellers
  UNION ALL SELECT 'ods_geolocation',                'zip+lat+lng',                             COUNT(*), COUNT(DISTINCT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng) FROM ods_geolocation
  UNION ALL SELECT 'ods_category_translation',       'product_category_name',                   COUNT(*), COUNT(DISTINCT product_category_name)                 FROM ods_category_translation
) x;

SELECT 'ods_orders.order_id' AS chk, COUNT(*) AS rows_n, COUNT(DISTINCT order_id) AS uniq_n,
       COUNT(*) - COUNT(DISTINCT order_id) AS dup_rows FROM ods_orders
UNION ALL SELECT 'ods_order_items.order_id', COUNT(*), COUNT(DISTINCT order_id), COUNT(*) - COUNT(DISTINCT order_id) FROM ods_order_items
UNION ALL SELECT 'ods_order_payments.order_id', COUNT(*), COUNT(DISTINCT order_id), COUNT(*) - COUNT(DISTINCT order_id) FROM ods_order_payments
UNION ALL SELECT 'ods_order_reviews.order_id', COUNT(*), COUNT(DISTINCT order_id), COUNT(*) - COUNT(DISTINCT order_id) FROM ods_order_reviews
UNION ALL SELECT 'ods_order_reviews.review_id', COUNT(*), COUNT(DISTINCT review_id), COUNT(*) - COUNT(DISTINCT review_id) FROM ods_order_reviews
UNION ALL SELECT 'ods_customers.customer_unique_id', COUNT(*), COUNT(DISTINCT customer_unique_id), COUNT(*) - COUNT(DISTINCT customer_unique_id) FROM ods_customers
UNION ALL SELECT 'ods_geolocation.zip_prefix', COUNT(*), COUNT(DISTINCT geolocation_zip_code_prefix), COUNT(*) - COUNT(DISTINCT geolocation_zip_code_prefix) FROM ods_geolocation;

SELECT 'ods_customers' AS tbl, 'customer_unique_id' AS real_entity,
       COUNT(DISTINCT customer_unique_id) AS entities,
       COUNT(DISTINCT customer_id)        AS rows_per_entity_total,
       (SELECT MAX(c) FROM (SELECT COUNT(*) c FROM ods_customers GROUP BY customer_unique_id) t) AS max_rows_per_entity
FROM ods_customers
UNION ALL
SELECT 'ods_geolocation', 'zip_code_prefix',
       COUNT(DISTINCT geolocation_zip_code_prefix), COUNT(*),
       (SELECT MAX(c) FROM (SELECT COUNT(*) c FROM ods_geolocation GROUP BY geolocation_zip_code_prefix) t)
FROM ods_geolocation;

SELECT MAX(order_item_id)                     AS max_as_text,
       MAX(CAST(order_item_id AS UNSIGNED))   AS max_as_int,
       COUNT(DISTINCT order_item_id)          AS distinct_vals
FROM ods_order_items;

SELECT (SELECT COUNT(*) FROM ods_orders) AS orders_n,
       (SELECT COUNT(*) FROM ods_orders o
          JOIN ods_order_items    i ON o.order_id = i.order_id
          JOIN ods_order_payments p ON o.order_id = p.order_id
          JOIN ods_order_reviews  r ON o.order_id = r.order_id) AS joined_n,
       (SELECT ROUND(SUM(price + freight_value), 2) FROM ods_order_items) AS gmv_true,
       (SELECT ROUND(SUM(i.price + i.freight_value), 2) FROM ods_orders o
          JOIN ods_order_items    i ON o.order_id = i.order_id
          JOIN ods_order_payments p ON o.order_id = p.order_id
          JOIN ods_order_reviews  r ON o.order_id = r.order_id) AS gmv_joined;

SELECT (SELECT COUNT(*) FROM ods_customers c
          JOIN ods_geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix) AS customers_x_geo;
