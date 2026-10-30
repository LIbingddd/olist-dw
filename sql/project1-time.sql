SELECT 'orders.order_purchase_timestamp' AS col,
       MIN(order_purchase_timestamp) AS min_v, MAX(order_purchase_timestamp) AS max_v,
       SUM(LENGTH(order_purchase_timestamp) NOT IN (0, 19)) AS bad_len FROM ods_orders
UNION ALL SELECT 'orders.order_approved_at',
       MIN(order_approved_at), MAX(order_approved_at),
       SUM(LENGTH(order_approved_at) NOT IN (0, 19)) FROM ods_orders
UNION ALL SELECT 'orders.order_delivered_carrier_date',
       MIN(order_delivered_carrier_date), MAX(order_delivered_carrier_date),
       SUM(LENGTH(order_delivered_carrier_date) NOT IN (0, 19)) FROM ods_orders
UNION ALL SELECT 'orders.order_delivered_customer_date',
       MIN(order_delivered_customer_date), MAX(order_delivered_customer_date),
       SUM(LENGTH(order_delivered_customer_date) NOT IN (0, 19)) FROM ods_orders
UNION ALL SELECT 'orders.order_estimated_delivery_date',
       MIN(order_estimated_delivery_date), MAX(order_estimated_delivery_date),
       SUM(LENGTH(order_estimated_delivery_date) NOT IN (0, 19)) FROM ods_orders
UNION ALL SELECT 'order_items.shipping_limit_date',
       MIN(shipping_limit_date), MAX(shipping_limit_date),
       SUM(LENGTH(shipping_limit_date) NOT IN (0, 19)) FROM ods_order_items
UNION ALL SELECT 'order_reviews.review_creation_date',
       MIN(review_creation_date), MAX(review_creation_date),
       SUM(LENGTH(review_creation_date) NOT IN (0, 19)) FROM ods_order_reviews
UNION ALL SELECT 'order_reviews.review_answer_timestamp',
       MIN(review_answer_timestamp), MAX(review_answer_timestamp),
       SUM(LENGTH(review_answer_timestamp) NOT IN (0, 19)) FROM ods_order_reviews;

SELECT 'orders.order_purchase_timestamp' AS col,
       SUM(order_purchase_timestamp > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) AS future_n FROM ods_orders
UNION ALL SELECT 'orders.order_approved_at',
       SUM(order_approved_at > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) FROM ods_orders
UNION ALL SELECT 'orders.order_delivered_carrier_date',
       SUM(order_delivered_carrier_date > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) FROM ods_orders
UNION ALL SELECT 'orders.order_delivered_customer_date',
       SUM(order_delivered_customer_date > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) FROM ods_orders
UNION ALL SELECT 'orders.order_estimated_delivery_date',
       SUM(order_estimated_delivery_date > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) FROM ods_orders
UNION ALL SELECT 'order_items.shipping_limit_date',
       SUM(shipping_limit_date > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) FROM ods_order_items
UNION ALL SELECT 'order_reviews.review_creation_date',
       SUM(review_creation_date > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) FROM ods_order_reviews
UNION ALL SELECT 'order_reviews.review_answer_timestamp',
       SUM(review_answer_timestamp > DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s')) FROM ods_order_reviews;

SELECT SUM(order_approved_at <> '' AND order_approved_at < order_purchase_timestamp) AS approved_before_purchase,
       SUM(order_approved_at <> '' AND order_delivered_carrier_date <> ''
           AND order_delivered_carrier_date < order_approved_at) AS carrier_before_approved,
       SUM(order_delivered_carrier_date <> '' AND order_delivered_customer_date <> ''
           AND order_delivered_customer_date < order_delivered_carrier_date) AS delivered_before_carrier,
       SUM(order_delivered_customer_date <> ''
           AND order_delivered_customer_date < order_purchase_timestamp) AS delivered_before_purchase,
       SUM(order_estimated_delivery_date <> ''
           AND order_estimated_delivery_date < order_purchase_timestamp) AS estimate_before_purchase
FROM ods_orders;

SELECT LEFT(order_purchase_timestamp, 4) AS yr,
       COUNT(*) AS orders,
       SUM(order_status = 'delivered') AS delivered,
       MIN(order_purchase_timestamp) AS first_ts,
       MAX(order_purchase_timestamp) AS last_ts
FROM ods_orders
GROUP BY yr
ORDER BY yr;

SELECT COUNT(*) AS delivered_orders,
       MIN(d) AS min_days,
       MAX(d) AS max_days,
       ROUND(AVG(d), 1) AS avg_days,
       SUM(d < 0) AS negative_lag,
       SUM(d > 180) AS over_180d
FROM (SELECT DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS d
      FROM ods_orders WHERE order_delivered_customer_date <> '') t;

SELECT order_id, order_status, order_purchase_timestamp,
       order_delivered_customer_date,
       DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS lag_days
FROM ods_orders
WHERE order_delivered_customer_date <> ''
ORDER BY lag_days DESC
LIMIT 5;
