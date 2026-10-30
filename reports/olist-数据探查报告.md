# Olist 电商数据集 · 数据探查报告

- 探查人：LIbingddd
- 日期：2026-10-30
- 数据来源：Kaggle `olistbr/brazilian-ecommerce`（2026-10 下载，9 个 CSV，解压后 120 MB）
- 环境：Docker + MySQL 8.0，库 `olist`，9 张 `ods_` 表
- 全部结论来自 `sql/` 下四份只读脚本，原始输出在 `reports/`。对应关系见附录。

---

## 1. 数据概览

| 表 | 行数 | 字段数 | 一行代表 | 时间范围 |
|---|---:|---:|---|---|
| `ods_orders` | 99,441 | 8 | 一笔订单 | 2016-09-04 ~ 2018-10-17 |
| `ods_order_items` | 112,650 | 7 | 订单里的一个商品 | 2016-09-19 ~ 2020-04-09 |
| `ods_order_payments` | 103,886 | 5 | 一笔支付流水 | 无时间字段 |
| `ods_order_reviews` | 99,224 | 7 | 一条评价 | 2016-10-02 ~ 2018-08-31 |
| `ods_customers` | 99,441 | 5 | 一次下单的客户记录 | 无时间字段 |
| `ods_sellers` | 3,095 | 4 | 一个卖家 | 无时间字段 |
| `ods_products` | 32,951 | 9 | 一个商品 | 无时间字段 |
| `ods_geolocation` | 1,000,163 | 5 | 一个坐标采样点 | 无时间字段 |
| `ods_category_translation` | 71 | 2 | 一个葡语类目名 | 无时间字段 |
| **合计** | **1,550,922** | **52** | | |

9 张表的 `COUNT(*)` 与 Kaggle 官方文档给出的行数**逐个相等，差 0 行**。`ods_order_items` 的时间范围上限 2020-04-09 不是数据截止时间，是 4 行运费期限的录入错误（见 D7）。

数据跨度 25 个月，但分布极不均匀：

| 年份 | 订单数 | 占比 |
|---|---:|---:|
| 2016 | 329 | 0.33% |
| 2017 | 45,101 | 45.35% |
| 2018 | 54,011 | 54.31% |

2016 年只有 329 单（数据从 2016-09-04 才开始），2018 年截止到 10-17。**做同比、做趋势，两端都不能用。**

---

## 2. 表结构与关系

### 2.1 主键候选

候选键必须包含复合键。只测单列会得出「`ods_order_items` 没有主键」的错误结论——它的 `order_id` 重复 13,984 次，但 `(order_id, order_item_id)` 完全唯一。

| 表 | 候选键 | 行数 | 唯一值 | 重复行 | 判定 |
|---|---|---:|---:|---:|---|
| `ods_orders` | `order_id` | 99,441 | 99,441 | 0 | OK |
| `ods_order_items` | `order_id + order_item_id` | 112,650 | 112,650 | 0 | OK |
| `ods_order_payments` | `order_id + payment_sequential` | 103,886 | 103,886 | 0 | OK |
| `ods_order_reviews` | `review_id + order_id` | 99,224 | 99,224 | 0 | OK |
| `ods_customers` | `customer_id` | 99,441 | 99,441 | 0 | OK（语义见 D3） |
| `ods_products` | `product_id` | 32,951 | 32,951 | 0 | OK |
| `ods_sellers` | `seller_id` | 3,095 | 3,095 | 0 | OK |
| `ods_geolocation` | `zip + lat + lng` | 1,000,163 | 720,154 | **279,009** | **无主键** |
| `ods_category_translation` | `product_category_name` | 71 | 71 | 0 | OK |

### 2.2 外键关系与基数

| 关系 | 基数 | 单边最大值 | 说明 |
|---|---|---|---|
| `items.order_id → orders.order_id` | N:1 | 21 | 一个订单最多 21 个商品 |
| `payments.order_id → orders.order_id` | N:1 | 29 | 一个订单最多 29 笔支付 |
| `reviews.order_id → orders.order_id` | N:1 | 3 | 547 个订单有多条评价（多出 551 行） |
| `orders.customer_id → customers.customer_id` | 1:1 | 1 | 严格一对一，不是 N:1 |
| `items.product_id → products.product_id` | N:1 | — | 无孤儿 |
| `items.seller_id → sellers.seller_id` | N:1 | — | 无孤儿 |

**三条 N:1 关系是全部膨胀风险的来源。** 它们不报错，只会让 `COUNT(*)` 和 `SUM()` 静默变大。

---

## 3. 粒度

这一节决定后面所有聚合的口径，写错一个，整张报表都错。

| 表 | 一行代表 | 容易误读成 |
|---|---|---|
| `ods_orders` | 一笔订单 | — |
| `ods_order_items` | 订单里的**一个商品** | 一笔订单（会漏掉多商品单） |
| `ods_order_payments` | 一笔**支付流水** | 一笔订单的支付（一个订单最多拆 29 笔） |
| `ods_order_reviews` | 一条**评价** | 一笔订单的评价（547 个订单有多条） |
| `ods_customers` | 一次下单的**客户记录** | 一个客户（96,096 个人对应 99,441 条） |
| `ods_geolocation` | 一个**坐标采样点** | 一个邮编（19,015 个邮编对应 100 万行） |
| `ods_category_translation` | 一个葡语类目名 | — |

**三处最容易错**：`order_items` 不是订单、`payments` 不是订单的支付、`customers` 不是人。前两个会让金额翻倍，第三个会让复购率算成 0。

---

## 4. 空值分析

52 列里只有 6 列有缺失，其余 46 列空值率 0.00%。

| 列 | 空值数 | 空串数 | 占比 |
|---|---:|---:|---:|
| `ods_order_reviews.review_comment_title` | 87,656 | 0 | 88.34% |
| `ods_order_reviews.review_comment_message` | 58,247 | 0 | 58.70% |
| `ods_orders.order_delivered_customer_date` | 0 | 2,965 | 2.98% |
| `ods_products.product_category_name` | 0 | 610 | 1.85% |
| `ods_orders.order_delivered_carrier_date` | 0 | 1,783 | 1.79% |
| `ods_orders.order_approved_at` | 0 | 160 | 0.16% |

### 4.1 同一个库里，缺失值有两种表示法

看「空值数」和「空串数」两列的对比，规律非常整齐：

- `ods_order_reviews` 走 Spark 经 JDBC 写入 → 真 `NULL`，空串数全是 0
- 其余 8 张表走 `LOAD DATA` 导入 → 空字符串 `''`，空值数全是 0

**任何下游检查都必须两种都算。** 只写 `IS NULL` 会漏掉 2,965 行未送达订单，只写 `= ''` 会漏掉 87,656 条空评论标题。

### 4.2 2,965 个缺失里，只有 8 个是真异常

| `order_status` | 订单数 | 无送达时间 | 判定 |
|---|---:|---:|---|
| delivered | 96,478 | **8** | **真异常** |
| shipped | 1,107 | 1,107 | 结构性：还没送到 |
| canceled | 625 | 619 | 结构性 |
| unavailable | 609 | 609 | 结构性 |
| invoiced / processing / created / approved | 622 | 622 | 结构性：还没发货 |
| **合计** | **99,441** | **2,965** | 2,957 结构性 + 8 异常 |

98.7% 的空值是「业务上本来就没有」，只有 8 行是「应该有但没有」。

---

## 5. 重复与唯一性

### 5.1 单列唯一 ≠ 语义正确

`ods_customers.customer_id` 唯一性测试全过（99,441 / 99,441，diff = 0），但它是**一单一 id**：96,096 个人对应 99,441 个 id，同一个人最多下过 17 单。**唯一性完美，反而会骗过你。** 真正的人要用 `customer_unique_id`。

### 5.2 没有主键的表

`ods_geolocation` 连 `zip + lat + lng` 三列组合都不唯一（重复 279,009 行）。19,015 个邮编对应 100 万行，单个邮编最多 1,146 行。它是**原始坐标采样表**，不是邮编维表。

### 5.3 重复带来的放大（实测，不是估算）

| 连接方式 | 结果 | 放大 |
|---|---|---|
| 四表按 `order_id` 全连接 | 117,329 行（订单 99,441） | +18% |
| 同上，GMV | 15,843,553.24 → 16,490,809.55 | +4.09% |
| 最坏一单（3 商品 × 21 支付 × 1 评价） | 63 行，金额 161.32 → 3,387.72 | **21 倍** |
| `customers` 按邮编 join `geolocation` | 99,441 → 15,083,455 行 | **152 倍** |

这些查询都不会报错，`COUNT(*)` 和 `SUM()` 全部照常返回，只是数字错了。

---

## 6. 脏数据清单

### D1 同一个库里缺失值有两种表示法

**现象**：8 张表用空串表示缺失，`ods_order_reviews` 用真 `NULL`。
**证据**：`sql/project1-nulls.sql`，看 `n_null` 与 `n_blank` 两列的分布。
**影响**：只写一种判空，漏掉一半缺失。
**处理**：DWD 层统一转成 `NULL`，判空只写 `IS NULL`。

### D2 `ods_geolocation` 没有主键

**现象**：`zip + lat + lng` 三列组合重复 279,009 行。
**证据**：`sql/project1-keys.sql` 第 1 个结果集，`verdict = NOT A KEY`。
**影响**：当维度直接 join，`customers` 从 99,441 行变成 15,083,455 行。
**处理**：先聚合到邮编级（lat/lng 取中位数），19,015 行，再当维度用。

### D3 `customer_id` 是一单一 id，不是一个人

**现象**：99,441 个 `customer_id` 对应 96,096 个 `customer_unique_id`。
**证据**：`sql/project1-keys.sql` 第 3 个结果集，`entities = 96,096`、`max_rows_per_entity = 17`。
**影响**：用 `customer_id` 算复购率会得到 0。
**处理**：客户维建在 `customer_unique_id` 上。

### D4 `order_item_id` 存成了字符串

**现象**：`MAX(order_item_id)` 返回 `'9'`，`MAX(CAST(... AS UNSIGNED))` 返回 `21`。
**证据**：`sql/project1-keys.sql` 第 4 个结果集，`max_as_text` vs `max_as_int`。
**影响**：`ORDER BY order_item_id` 排成 `1, 10, 11, 12, 2, 3...`，所有依赖排序和取最大的逻辑静默出错。
**处理**：DWD 层转 `INT`。

### D5 775 单有订单、没有商品行

**现象**：`orders` 左连接 `items` 得到 775 条孤儿。
**证据**：`sql/project1-consistency.sql` 第 1 个结果集，`orders_no_item = 775`。
**影响**：看起来像 ETL 丢数，实际不是。
**处理**：按状态拆开——unavailable 603 + canceled 164 + created 5 + invoiced 2 + shipped 1。**774 单是商品行从来没生成过**（取消/不可用），只有 1 单 `shipped` 是真异常。这些订单不该进商品粒度的事实表，但要保留在订单粒度表里并打 `has_item = 0`。

### D6 支付总额比商品总额多 16.5 万

**现象**：商品总额 15,843,553.24，支付总额 16,008,872.12，差 165,318.88。
**证据**：`sql/project1-consistency.sql` 第 3 个结果集。
**影响**：用支付表算 GMV 会虚高 1%。
**处理**：拆开看——772 单「无商品行但有支付」合计 162,591.95，占差额的 **98.4%**，全是取消/不可用的退款流水。真正「有商品行却对不上」的只有 360 单（284 单支付多、76 单商品多）。**GMV 一律用商品行算。**

### D7 4 行运费期限落在 2020 年

**现象**：`shipping_limit_date` 最大 2020-04-09，比下单时间晚 1,052–1,056 天。
**证据**：`sql/project1-time.sql` 第 1 个结果集，`max_v` 列。
**影响**：算「卖家发货超时率」时这 4 行永远不会超时，指标被悄悄压低，而且查不出来。
**处理**：3 个订单 4 行明细，时分秒完全一致，是**年份被改过**（2017 → 2020）。DWD 层加约束：`shipping_limit_date ≤ order_purchase_timestamp + 90 天`。

### D8 42 行经纬度越出巴西

**现象**：合法范围 lat ∈ [-34, 6]、lng ∈ [-74, -34]，实际极值 lat 45.07、lng 121.10。
**证据**：`sql/project1-consistency.sql` 第 2 个结果集，`geo_out_of_brazil = 42`。
**影响**：做地理分布图时这 42 行会把地图缩放到三大洲。
**处理**：DWD 层过滤，占 0.004%。

### D9 状态与事实矛盾

**现象**：6 单 `canceled` 却有送达时间；8 单 `delivered` 却没有送达时间。
**证据**：`sql/project1-consistency.sql` 第 5 个结果集。
**影响**：履约率、准时率的分母会算错。
**处理**：6 单取消有送达的，5 单在 2016 年（Olist 早期数据），合理解释是「送达后退货」，做履约指标时单列或排除；8 单缺送达时间的保留，`delivery_days` 记 `NULL`，不补 0。

### D10 64 条评价早于下单

**现象**：`review_creation_date` 早于 `order_purchase_timestamp`，最多早 111 天，16 条超过 30 天。
**证据**：`sql/project1-consistency.sql` 第 6 个结果集，`review_before_purchase = 64`。
**影响**：评价不可能发生在购买之前，这 64 条无法用业务解释。
**处理**：占比 0.06%，DWD 层标记 `is_time_conflict = 1`，不删。**注意另一条不是脏数据**：`review_before_delivery` 有 5,127 条，但 `review_creation_date` 是平台发出问卷的时间，不是顾客提交的时间，两者口径不同，不能拿来比先后。

---

## 7. 异常值

| 检查项 | 命中 | 占比 | 判定 |
|---|---:|---:|---|
| 价格为 0 / 负数 | 0 / 0 | 0 | 干净 |
| 运费为 0 | 383 | 0.34% | **正常**，包邮 |
| 分期数为 0 | 2 | 0.002% | 异常 |
| 分期 > 12（最大 24） | 185 | 0.18% | **正常**，巴西信用卡支持 24 期 |
| 支付金额为 0 | 9 | 0.009% | 6 笔 voucher + 3 笔 not_defined |
| 评分不在 1–5 | 0 | 0 | 干净 |
| 经纬度越界 | 42 | 0.004% | 异常（D8） |
| 商品重量为 0 | 6 | 0.02% | 异常 |
| 商品尺寸有 0 | 2 | 0.006% | 异常 |

### 7.1 3σ 法则在这个数据集上无效

支付金额：均值 154.10，标准差 217.49，**3σ 上界 806.58**，超过这个值的有 **1,803 笔**，最大 13,664.08。

**但这 1,803 笔全是正常的大额订单。** 支付金额右偏严重（长尾），不服从正态分布，3σ 对它没有意义。**偏斜分布要用分位数（IQR / P99），不能用均值 ± kσ。**

### 7.2 阈值必须来自业务规则

「分期 > 12 是异常」这条常见经验在这里是错的——巴西信用卡的标准分期上限就是 24 期，185 笔超 12 期的全是合规业务。照搬直觉阈值，等于把自己的业务常识缺口暴露出来。

---

## 8. 对建模的影响

### 8.1 事实表与维表

| 层 | 表 | 粒度 | 行数 | 主键 |
|---|---|---|---:|---|
| 事实 | `dwd_order_items` | 一行一商品 | 112,650 | `(order_id, order_item_id)` |
| 事实 | `dwd_order` | 一行一单 | 99,441 | `order_id` |
| 维 | `dim_customer` | 一个人 | 96,096 | `customer_unique_id` |
| 维 | `dim_product` | 一个商品 | 32,951 | `product_id` |
| 维 | `dim_seller` | 一个卖家 | 3,095 | `seller_id` |
| 维 | `dim_geo` | 一个邮编 | 19,015 | `zip_code_prefix` |
| 维 | `dim_category` | 一个类目 | 71 | `product_category_name` |

**事实表选 `order_items`，不是 `orders`。** `orders` 是它的聚合视图，不是并列的事实表。两张都建是因为下游既要商品维度也要订单时效。

### 8.2 主键怎么定

- `dwd_order_items`：`(order_id, order_item_id)`，`order_item_id` 转 `INT`（D4）
- `dwd_order`：`order_id`
- `dim_customer`：`customer_unique_id`（D3），`customer_id` 降级为普通列
- `dim_geo`：`zip_code_prefix`，由 100 万行采样聚合而来（D2）

**`order_id` 不是「9 张表共用的主键」。** 9 张表就有 9 个主键，`order_id` 只在订单粒度上唯一。

### 8.3 哪些字段要清洗

| 字段 | 从 | 到 | 理由 |
|---|---|---|---|
| `price` / `freight_value` / `payment_value` | VARCHAR | `DECIMAL(10,2)` | ODS 存 VARCHAR 是为了看得见空串，DWD 要能算 |
| `order_item_id` / `payment_sequential` / `payment_installments` | VARCHAR | `INT` | 排序和取最大值 |
| 5 个时间列 | VARCHAR(19) | `DATETIME` | 要算时间差、要建分区 |
| 所有空串 | `''` | `NULL` | 统一缺失表示（D1） |
| 4 行运费期限 | 2020 年 | 标记异常，不改值 | 保留原始值才能追溯（D7） |

### 8.4 分区键

选 `order_purchase_timestamp` 的年月。

理由：① 下游查询几乎都带时间范围；② 数据本身按时间增长，增量导入天然按这个字段切；③ 不用 `order_status`——状态会变，分区会漂移。

### 8.5 哪些行要在 DWD 层过滤

| 处理 | 行数 | 理由 |
|---|---:|---|
| 过滤 `ods_geolocation` 境外坐标 | 42 | D8，占 0.004% |
| 不删，标记 `shipping_limit` 异常 | 4 | D7，保留原值可追溯 |
| 不进商品事实表 | 775 单 | D5，本来就没有商品行 |
| 不删，`delivery_days` 记 NULL | 8 单 | D9，补 0 会拉低平均时效 |
| 不删，标记 `is_time_conflict` | 64 | D10，占比极小 |

### 8.6 `payments` 和 `reviews` 不能直接 join 主事实表

必须先聚合到订单粒度：

- `payments`：一个订单最多 29 笔，按 `order_id` 聚成 `SUM(payment_value)`、`COUNT(*)`、`MAX(payment_type)`
- `reviews`：547 个订单有多条，按 `order_id` 取最新一条

直接 join 会让金额膨胀 18%（5.3）。

---

## 附录：脚本与结论的对应

| 章节 | 脚本 | 结果集 | 原始输出 |
|---|---|---|---|
| 1、5.1、5.2 | `sql/project1-keys.sql` | 1（候选键）、2（单列唯一）、3（粒度） | `reports/keys.txt` |
| 4 | `sql/project1-nulls.sql` | 1（52 列空值率） | `reports/nulls.txt` |
| 1、D7 | `sql/project1-time.sql` | 1（范围与格式）、4（按年分布） | `reports/time.txt` |
| 6、7 | `sql/project1-consistency.sql` | 1（孤儿）、2（异常值）、3（金额）、5（状态）、6（跨表时间） | `reports/consistency.txt` |

复现方式（PowerShell）：

```powershell
cd D:\github\work\spark-hello
Get-Content -Raw sql\project1-consistency.sql | docker compose exec -T mysql sh -c "MYSQL_PWD=`$MYSQL_ROOT_PASSWORD mysql -uroot -t olist"
```

### 还没做的

- **DWD / DWS / ADS 还没建。** 这份报告只到「看清数据」，第 8 节是给下一层的输入，不是已经建好的模型。
- 那 8 单 `delivered` 却没有送达时间，数据里没有更多线索，判断不了是上游漏记还是 ETL 丢了。
- 1 单 delivered 但完全没有支付记录（`bfbd0f9b…`，2016-09-15，3 个商品），可能是线下付款或测试单，无法确认。
- 64 条评价早于下单，`review_id` 是否被复用没有原始日志，判断不了。
