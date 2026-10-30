import os

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

JDBC_URL = (
    "jdbc:mysql://mysql:3306/shop"
    "?useSSL=false"
    "&allowPublicKeyRetrieval=true"
    "&serverTimezone=Asia/Shanghai"
    "&characterEncoding=utf8"
)
JDBC_PROPS = {
    "user": "root",
    "password": os.environ["MYSQL_ROOT_PASSWORD"],
    "driver": "com.mysql.cj.jdbc.Driver",
}


def main():
    spark = (
        SparkSession.builder
        .appName("hello-spark-jdbc")
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("WARN")

    print("=" * 60)
    print("[1/5] 连接 MySQL:", JDBC_URL.split("?")[0])

    print("[2/5] 读取源表 shop.orders")
    orders = spark.read.jdbc(url=JDBC_URL, table="orders", properties=JDBC_PROPS)
    orders.printSchema()
    orders.show(5, truncate=False)
    total_rows = orders.count()
    print("源表行数 =", total_rows)
    if total_rows == 0:
        raise SystemExit("源表是空的，检查 init/01_schema.sql 是否执行过")

    print("[3/5] 按类目聚合")
    summary = (
        orders.groupBy("category")
        .agg(
            F.count("*").alias("order_cnt"),
            F.round(F.sum("amount"), 2).alias("total_amount"),
            F.round(F.avg("amount"), 2).alias("avg_amount"),
        )
        .orderBy(F.desc("total_amount"))
    )
    summary.show(truncate=False)

    print("[4/5] 写回 MySQL 表 shop.category_summary")
    expected = summary.count()
    (
        summary.write
        .mode("overwrite")
        .option("truncate", "true")
        .jdbc(url=JDBC_URL, table="category_summary", properties=JDBC_PROPS)
    )
    print(f"写入完成，应有 {expected} 行")

    print("[5/5] 回读校验")
    check = spark.read.jdbc(url=JDBC_URL, table="category_summary", properties=JDBC_PROPS)
    check.orderBy(F.desc("total_amount")).show(truncate=False)
    got = check.count()
    print(f"结果表行数 = {got}（应为 {expected}）")
    if got != expected:
        raise SystemExit("回读行数和聚合结果对不上，写入有问题")
    print("=" * 60)
    print("OK：端到端跑通")

    spark.stop()


if __name__ == "__main__":
    main()
