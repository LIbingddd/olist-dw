SELECT 'orders_no_item' AS chk, COUNT(*) AS n FROM ods_orders o
  LEFT JOIN ods_order_items i ON i.order_id = o.order_id WHERE i.order_id IS NULL
UNION ALL SELECT 'orders_no_payment', COUNT(*) FROM ods_orders o
  LEFT JOIN ods_order_payments p ON p.order_id = o.order_id WHERE p.order_id IS NULL
UNION ALL SELECT 'orders_no_review', COUNT(*) FROM ods_orders o
  LEFT JOIN ods_order_reviews r ON r.order_id = o.order_id WHERE r.order_id IS NULL
UNION ALL SELECT 'orders_no_customer', COUNT(*) FROM ods_orders o
  LEFT JOIN ods_customers c ON c.customer_id = o.customer_id WHERE c.customer_id IS NULL
UNION ALL SELECT 'item_no_order', COUNT(*) FROM ods_order_items i
  LEFT JOIN ods_orders o ON o.order_id = i.order_id WHERE o.order_id IS NULL
UNION ALL SELECT 'payment_no_order', COUNT(*) FROM ods_order_payments p
  LEFT JOIN ods_orders o ON o.order_id = p.order_id WHERE o.order_id IS NULL
UNION ALL SELECT 'review_no_order', COUNT(*) FROM ods_order_reviews r
  LEFT JOIN ods_orders o ON o.order_id = r.order_id WHERE o.order_id IS NULL
UNION ALL SELECT 'item_no_product', COUNT(*) FROM ods_order_items i
  LEFT JOIN ods_products p ON p.product_id = i.product_id WHERE p.product_id IS NULL
UNION ALL SELECT 'item_no_seller', COUNT(*) FROM ods_order_items i
  LEFT JOIN ods_sellers s ON s.seller_id = i.seller_id WHERE s.seller_id IS NULL
UNION ALL SELECT 'customer_no_geo', COUNT(*) FROM ods_customers c
  LEFT JOIN (SELECT DISTINCT geolocation_zip_code_prefix z FROM ods_geolocation) g
    ON g.z = c.customer_zip_code_prefix WHERE g.z IS NULL
UNION ALL SELECT 'seller_no_geo', COUNT(*) FROM ods_sellers s
  LEFT JOIN (SELECT DISTINCT geolocation_zip_code_prefix z FROM ods_geolocation) g
    ON g.z = s.seller_zip_code_prefix WHERE g.z IS NULL
UNION ALL SELECT 'product_no_category', COUNT(*) FROM ods_products p
  LEFT JOIN ods_category_translation t ON t.product_category_name = p.product_category_name
  WHERE p.product_category_name <> '' AND t.product_category_name IS NULL;

SELECT 'price_zero' AS chk, COUNT(*) AS n FROM ods_order_items WHERE price + 0 = 0
UNION ALL SELECT 'price_negative', COUNT(*) FROM ods_order_items WHERE price + 0 < 0
UNION ALL SELECT 'freight_zero', COUNT(*) FROM ods_order_items WHERE freight_value + 0 = 0
UNION ALL SELECT 'freight_negative', COUNT(*) FROM ods_order_items WHERE freight_value + 0 < 0
UNION ALL SELECT 'installments_zero', COUNT(*) FROM ods_order_payments WHERE payment_installments + 0 = 0
UNION ALL SELECT 'installments_gt12', COUNT(*) FROM ods_order_payments WHERE payment_installments + 0 > 12
UNION ALL SELECT 'installments_max', (SELECT MAX(payment_installments + 0) FROM ods_order_payments)
UNION ALL SELECT 'pay_value_zero', COUNT(*) FROM ods_order_payments WHERE payment_value + 0 = 0
UNION ALL SELECT 'pay_value_negative', COUNT(*) FROM ods_order_payments WHERE payment_value + 0 < 0
UNION ALL SELECT 'review_score_out_of_1_5', COUNT(*) FROM ods_order_reviews
  WHERE review_score + 0 NOT BETWEEN 1 AND 5
UNION ALL SELECT 'geo_out_of_brazil', COUNT(*) FROM ods_geolocation
  WHERE geolocation_lat + 0 NOT BETWEEN -34 AND 6
     OR geolocation_lng + 0 NOT BETWEEN -74 AND -34
UNION ALL SELECT 'product_weight_zero', COUNT(*) FROM ods_products WHERE product_weight_g + 0 = 0
UNION ALL SELECT 'product_dim_zero', COUNT(*) FROM ods_products
  WHERE product_length_cm + 0 = 0 OR product_height_cm + 0 = 0 OR product_width_cm + 0 = 0;

SELECT COUNT(*) AS orders_cmp,
       SUM(ABS(it_amt - pay_amt) < 0.01) AS matched,
       SUM(pay_amt > it_amt + 0.01) AS pay_more,
       SUM(it_amt > pay_amt + 0.01) AS item_more,
       ROUND(SUM(it_amt), 2) AS item_total,
       ROUND(SUM(pay_amt), 2) AS pay_total,
       ROUND(SUM(pay_amt) - SUM(it_amt), 2) AS gap
FROM (
  SELECT o.order_id, IFNULL(i.amt, 0) AS it_amt, IFNULL(p.amt, 0) AS pay_amt
  FROM ods_orders o
  LEFT JOIN (SELECT order_id, SUM(price + freight_value) AS amt
             FROM ods_order_items GROUP BY order_id) i ON i.order_id = o.order_id
  LEFT JOIN (SELECT order_id, SUM(payment_value + 0) AS amt
             FROM ods_order_payments GROUP BY order_id) p ON p.order_id = o.order_id
) t;

SELECT o.order_id,
       ROUND(IFNULL(i.amt, 0), 2) AS item_amt,
       ROUND(IFNULL(p.amt, 0), 2) AS pay_amt,
       ROUND(IFNULL(p.amt, 0) - IFNULL(i.amt, 0), 2) AS gap,
       p.types, p.n_pay, o.order_status
FROM ods_orders o
LEFT JOIN (SELECT order_id, SUM(price + freight_value) AS amt
           FROM ods_order_items GROUP BY order_id) i ON i.order_id = o.order_id
LEFT JOIN (SELECT order_id, SUM(payment_value + 0) AS amt,
                  GROUP_CONCAT(DISTINCT payment_type ORDER BY payment_type) AS types,
                  COUNT(*) AS n_pay
           FROM ods_order_payments GROUP BY order_id) p ON p.order_id = o.order_id
ORDER BY ABS(IFNULL(p.amt, 0) - IFNULL(i.amt, 0)) DESC
LIMIT 5;

SELECT o.order_status,
       COUNT(*) AS orders,
       SUM(i.order_id IS NOT NULL) AS with_item,
       SUM(p.order_id IS NOT NULL) AS with_payment,
       SUM(r.order_id IS NOT NULL) AS with_review,
       SUM(o.order_delivered_customer_date <> '') AS with_delivered_ts
FROM ods_orders o
LEFT JOIN (SELECT DISTINCT order_id FROM ods_order_items) i ON i.order_id = o.order_id
LEFT JOIN (SELECT DISTINCT order_id FROM ods_order_payments) p ON p.order_id = o.order_id
LEFT JOIN (SELECT DISTINCT order_id FROM ods_order_reviews) r ON r.order_id = o.order_id
GROUP BY o.order_status
ORDER BY orders DESC;

SELECT 'review_before_purchase' AS chk, COUNT(*) AS n
  FROM ods_order_reviews r JOIN ods_orders o ON o.order_id = r.order_id
  WHERE DATE(r.review_creation_date) < DATE(o.order_purchase_timestamp)
UNION ALL SELECT 'review_before_delivery', COUNT(*)
  FROM ods_order_reviews r JOIN ods_orders o ON o.order_id = r.order_id
  WHERE o.order_delivered_customer_date <> ''
    AND DATE(r.review_creation_date) < DATE(o.order_delivered_customer_date)
UNION ALL SELECT 'ship_limit_before_purchase', COUNT(*)
  FROM ods_order_items i JOIN ods_orders o ON o.order_id = i.order_id
  WHERE DATE(i.shipping_limit_date) < DATE(o.order_purchase_timestamp)
UNION ALL SELECT 'estimate_before_purchase', COUNT(*)
  FROM ods_orders
  WHERE order_estimated_delivery_date <> ''
    AND DATE(order_estimated_delivery_date) < DATE(order_purchase_timestamp)
UNION ALL SELECT 'answer_before_creation', COUNT(*)
  FROM ods_order_reviews
  WHERE review_answer_timestamp IS NOT NULL AND review_answer_timestamp < review_creation_date
UNION ALL SELECT 'ts_length_not_19', COUNT(*)
  FROM ods_orders WHERE order_purchase_timestamp <> '' AND LENGTH(order_purchase_timestamp) <> 19;

SELECT (SELECT COUNT(*) FROM ods_products) AS products,
       (SELECT COUNT(*) FROM ods_products WHERE product_category_name = '') AS products_no_cat,
       (SELECT COUNT(DISTINCT product_category_name) FROM ods_products
        WHERE product_category_name <> '') AS cats_in_products,
       (SELECT COUNT(*) FROM ods_category_translation) AS cats_translated,
       (SELECT COUNT(DISTINCT p.product_category_name) FROM ods_products p
        WHERE p.product_category_name <> ''
          AND NOT EXISTS (SELECT 1 FROM ods_category_translation t
                          WHERE t.product_category_name = p.product_category_name)) AS cats_missing;
