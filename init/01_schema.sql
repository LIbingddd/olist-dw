CREATE DATABASE IF NOT EXISTS shop DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE shop;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id   BIGINT        NOT NULL,
  user_id    BIGINT        NOT NULL,
  category   VARCHAR(32)   NOT NULL,
  amount     DECIMAL(10,2) NOT NULL,
  created_at DATETIME      NOT NULL,
  PRIMARY KEY (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO orders (order_id, user_id, category, amount, created_at) VALUES
  (1001, 501, 'phone',  3999.00, '2026-09-01 10:12:00'),
  (1002, 502, 'phone',  2599.00, '2026-09-01 11:35:00'),
  (1003, 503, 'phone',  4999.00, '2026-09-02 09:05:00'),
  (1004, 501, 'laptop', 6499.00, '2026-09-02 14:20:00'),
  (1005, 504, 'laptop', 5299.00, '2026-09-03 16:48:00'),
  (1006, 505, 'laptop', 8999.00, '2026-09-03 20:11:00'),
  (1007, 502, 'book',     59.00, '2026-09-04 08:30:00'),
  (1008, 506, 'book',     45.00, '2026-09-04 12:02:00'),
  (1009, 503, 'book',     78.00, '2026-09-05 19:27:00'),
  (1010, 507, 'book',     32.00, '2026-09-05 21:40:00'),
  (1011, 504, 'book',     88.00, '2026-09-06 10:15:00'),
  (1012, 508, 'book',     66.00, '2026-09-06 15:33:00'),
  (1013, 505, 'home',    299.00, '2026-09-07 09:48:00'),
  (1014, 509, 'home',    158.00, '2026-09-07 13:22:00'),
  (1015, 506, 'home',    459.00, '2026-09-08 17:06:00'),
  (1016, 510, 'home',     89.00, '2026-09-08 18:55:00'),
  (1017, 507, 'home',    220.00, '2026-09-09 11:10:00'),
  (1018, 508, 'beauty',  129.00, '2026-09-09 14:40:00'),
  (1019, 509, 'beauty',  349.00, '2026-09-10 16:25:00'),
  (1020, 510, 'beauty',  199.00, '2026-09-10 20:08:00');

DROP TABLE IF EXISTS category_summary;
CREATE TABLE category_summary (
  category     VARCHAR(32)   NOT NULL,
  order_cnt    BIGINT        NOT NULL,
  total_amount DECIMAL(14,2) NOT NULL,
  avg_amount   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT COUNT(*) AS orders_rows FROM orders;
