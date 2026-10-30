# olist-dw

Olist 巴西电商数据集（9 个 CSV、155 万行）落进 MySQL，搭一层 ODS，再逐张表探查，最后写一份报告。

数据开发岗的第一道工序：**先摸清数据长什么样，才敢建表**。

## 数据从哪来

Kaggle `olistbr/brazilian-ecommerce`，9 个 CSV，解压后约 120 MB，放到 `data/olist/`（不入库）。

## 怎么跑

### 1. 起环境

密码不进仓库。先复制模板，填成你要用的：

```powershell
Copy-Item .env.example .env
```

```powershell
cd D:\github\work\olist-dw
docker compose up -d
docker compose ps          # olist-mysql 显示 healthy 才算起来
```

`init/01_schema.sql` 会建一个 `shop` 库、20 行测试数据。它跟 Olist 没关系，只是让 `run.ps1` 能端到端验证「Docker + MySQL + Spark 三件套是通的」。`.\run.ps1` 就是跑这套自检。

### 2. 导入 ODS

```powershell
# 建库建表：9 张表全 VARCHAR，一个约束都不加
Get-Content -Raw sql\project1-ods-ddl.sql | docker compose exec -T mysql sh -c "MYSQL_PWD=`$MYSQL_ROOT_PASSWORD mysql -uroot"

# 8 张表走 LOAD DATA
Get-Content -Raw sql\project1-ods-load.sql | docker compose exec -T mysql sh -c "MYSQL_PWD=`$MYSQL_ROOT_PASSWORD mysql -uroot --local-infile=1 olist"
```

`ods_order_reviews` 导不进来——它的评论正文里有换行符，`LOAD DATA` 按行切会把一条记录切成好几行。这张表走 Spark，指定 `multiLine=true` 才能读对：

```powershell
docker compose exec spark-master /opt/spark/bin/spark-submit `
  --master spark://spark-master:7077 `
  --jars /opt/jobs/lib/mysql-connector-j-8.0.33.jar `
  /opt/py/project1-load_review.py
```

驱动 jar 不在仓库里，`run.ps1` 会检查，缺了自动下载。

### 3. 探查

四份脚本，全部只读。

```powershell
Get-Content -Raw sql\project1-keys.sql | docker compose exec -T mysql sh -c "MYSQL_PWD=`$MYSQL_ROOT_PASSWORD mysql -uroot -t olist"
```

| 脚本 | 看什么 | 输出 |
|---|---|---|
| `project1-keys.sql` | 每张表的候选键能不能唯一、粒度是什么、四表按 `order_id` 连起来膨胀多少 | `reports/keys.txt` |
| `project1-nulls.sql` | 52 列的空值率，NULL 和空串分开数 | `reports/nulls.txt` |
| `project1-time.sql` | 8 个时间列的范围、格式长度、事件先后顺序 | `reports/time.txt` |
| `project1-consistency.sql` | 孤儿记录、异常值、订单金额和支付金额对不对得上 | `reports/consistency.txt` |

`sql/nulls-generate.sql` 不是查询，是从 `information_schema` 生成上面那 52 条 `SELECT` 的生成器。输出 52 行，每行末尾带 `UNION ALL`（最后一行不带），拼起来直接能跑。第一次用它的时候我以为它会顺便把结果算出来，盯着屏幕看了半天才发现生成和执行是两件事。

## 导进去长什么样

9 张表、1,550,922 行、52 列。`COUNT(*)` 与 Kaggle 官方文档的行数**逐个相等，差 0 行**。

| 表 | 行数 | 一行代表 |
|---|---:|---|
| `ods_orders` | 99,441 | 一笔订单 |
| `ods_order_items` | 112,650 | 订单里的一个商品 |
| `ods_order_payments` | 103,886 | 一笔支付流水 |
| `ods_order_reviews` | 99,224 | 一条评价 |
| `ods_customers` | 99,441 | 一次下单的客户记录 |
| `ods_sellers` | 3,095 | 一个卖家 |
| `ods_products` | 32,951 | 一个商品 |
| `ods_geolocation` | 1,000,163 | 一个坐标采样点 |
| `ods_category_translation` | 71 | 一个葡语类目名 |

## 报告

[`reports/olist-数据探查报告.md`](reports/olist-数据探查报告.md)，8 节。前 7 节是「数据长什么样」，第 8 节是「这些发现怎么影响建模」。

几个跑完才知道的：

- **`ods_geolocation` 没有主键**。`zip + lat + lng` 三列组合都重复 279,009 行，100 万行只有 72 万唯一。当维度直接 join，`customers` 从 99,441 行变成 1,508 万行。
- **`ods_customers.customer_id` 是一单一 id，不是一个人**。96,096 个人对应 99,441 个 id。唯一性测试全过，反而骗过你；真正的人要用 `customer_unique_id`。
- **`order_item_id` 存成了字符串**。`MAX()` 返回 `'9'` 而不是 `21`，`ORDER BY` 排成 `1, 10, 11, 12, 2, 3...`。
- **775 单「有订单无商品」不是脏数据**。按状态拆开，603 unavailable + 164 canceled + 5 created + 2 invoiced + 1 shipped，商品行从来没生成过。只有那 1 单 `shipped` 是真异常。
- **支付总额比商品总额多 16.5 万**，其中 98.4% 来自 772 单取消/不可用的退款流水。GMV 得用商品行算，不能用支付表算。

## 踩的坑

环境类的在 [DOCKER-FIX.md](DOCKER-FIX.md)，这里记三条判断类的——它们比环境坑值钱，因为环境坑证明会装环境，判断坑证明会看数据。

1. **把 `order_id` 当成「连接 9 张表的主键」**。错在两点：`total = unique` 只在 `ods_orders` 成立（items 重复 13,984、payments 重复 4,446、reviews 重复 551）；另外 5 张表根本没有 `order_id` 这一列。实测四表全连接 117,329 行（+18%），最坏一单金额放大 21 倍。`order_id` 是对的「聚合后连接键」，不是「共用主键」。
2. **照搬「分期 > 12 是异常」**。185 笔分期超过 12，最大 24 期——巴西信用卡的标准上限就是 24 期，全是合规业务。阈值必须来自业务规则，不能来自直觉。
3. **拿 3σ 找支付金额的极端值**。均值 154.10、标准差 217.49，3σ 上界 806.58，命中 1,803 笔。这 1,803 笔全是正常的大额订单——支付金额右偏严重，不服从正态分布。偏斜数据要用分位数，不能用均值 ± kσ。

## 目录

```
olist-dw/
├── docker-compose.yml          mysql + spark master + spark worker
├── .env.example                密码模板，复制成 .env 再填
├── init/01_schema.sql          shop 库 + 20 行测试数据，给环境自检用
├── sql/
│   ├── project1-ods-ddl.sql    9 张表，全 VARCHAR
│   ├── project1-ods-load.sql   LOAD DATA 导入 8 张表
│   ├── project1-keys.sql       粒度与候选键
│   ├── project1-nulls.sql      52 列空值率
│   ├── project1-time.sql       时间范围与事件顺序
│   ├── project1-consistency.sql 孤儿记录、异常值、金额对账
│   ├── describe-tables.sql     列出 olist 的全部列
│   └── nulls-generate.sql      用元数据生成空值率 SQL
├── jobs/hello_spark.py         环境自检用的小作业
├── jobs/lib/                   MySQL 驱动，自己下，不入库
├── py/project1-load_review.py  reviews 表走 Spark，CSV 里有换行
├── data/olist/                 9 个 CSV，自己下，不入库
├── reports/                    探查输出 + 报告
├── run.ps1                     环境自检一键脚本
└── DOCKER-FIX.md               Docker 起不来的排查记录
```

## 还没做

- **DWD / DWS / ADS 还没建。** 现在只到「看清数据」，报告第 8 节是给下一层的输入，不是已经建好的模型。
- 那 8 单 `delivered` 却没有送达时间，数据里没有更多线索，判断不了是上游漏记还是 ETL 丢了。
- 64 条评价早于下单，`review_id` 是否被复用没有原始日志，判断不了。
