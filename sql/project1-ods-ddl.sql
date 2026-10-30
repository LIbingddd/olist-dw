CREATE DATABASE IF NOT EXISTS olist
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE olist;

DROP TABLE IF EXISTS ods_customers;
CREATE TABLE ods_customers (
  customer_id               VARCHAR(64),
  customer_unique_id        VARCHAR(64),
  customer_zip_code_prefix  VARCHAR(16),
  customer_city             VARCHAR(64),
  customer_state            VARCHAR(8)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_geolocation;
CREATE TABLE ods_geolocation (
  geolocation_zip_code_prefix VARCHAR(16),
  geolocation_lat             VARCHAR(32),
  geolocation_lng             VARCHAR(32),
  geolocation_city            VARCHAR(64),
  geolocation_state           VARCHAR(8)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_order_items;
CREATE TABLE ods_order_items (
  order_id             VARCHAR(64),
  order_item_id        VARCHAR(8),
  product_id           VARCHAR(64),
  seller_id            VARCHAR(64),
  shipping_limit_date  VARCHAR(32),
  price                VARCHAR(32),
  freight_value        VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_order_payments;
CREATE TABLE ods_order_payments (
  order_id              VARCHAR(64),
  payment_sequential    VARCHAR(8),
  payment_type          VARCHAR(32),
  payment_installments  VARCHAR(8),
  payment_value         VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_order_reviews;
CREATE TABLE ods_order_reviews (
  review_id                 VARCHAR(64),
  order_id                  VARCHAR(64),
  review_score              VARCHAR(8),
  review_comment_title      VARCHAR(255),
  review_comment_message    TEXT,
  review_creation_date      VARCHAR(32),
  review_answer_timestamp   VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_orders;
CREATE TABLE ods_orders (
  order_id                      VARCHAR(64),
  customer_id                   VARCHAR(64),
  order_status                  VARCHAR(32),
  order_purchase_timestamp      VARCHAR(32),
  order_approved_at             VARCHAR(32),
  order_delivered_carrier_date  VARCHAR(32),
  order_delivered_customer_date VARCHAR(32),
  order_estimated_delivery_date VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_products;
CREATE TABLE ods_products (
  product_id                  VARCHAR(64),
  product_category_name       VARCHAR(64),
  product_name_lenght         VARCHAR(16),
  product_description_lenght  VARCHAR(16),
  product_photos_qty          VARCHAR(16),
  product_weight_g            VARCHAR(16),
  product_length_cm           VARCHAR(16),
  product_height_cm           VARCHAR(16),
  product_width_cm            VARCHAR(16)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_sellers;
CREATE TABLE ods_sellers (
  seller_id                VARCHAR(64),
  seller_zip_code_prefix   VARCHAR(16),
  seller_city              VARCHAR(64),
  seller_state             VARCHAR(8)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS ods_category_translation;
CREATE TABLE ods_category_translation (
  product_category_name          VARCHAR(64),
  product_category_name_english  VARCHAR(64)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
