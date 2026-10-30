import os

from pyspark.sql import SparkSession

spark = (SparkSession.builder
         .appName("load-reviews")
         .getOrCreate())

df = (spark.read
      .option("header", "true")
      .option("multiLine", "true")
      .option("escape", '"')
      .csv("/data/olist/olist_order_reviews_dataset.csv"))

(df.write
   .mode("overwrite")
   .option("truncate", "true")
   .jdbc(url="jdbc:mysql://mysql:3306/olist?useSSL=false&allowPublicKeyRetrieval=true",
         table="ods_order_reviews",
         properties={"user": "root",
                     "password": os.environ["MYSQL_ROOT_PASSWORD"],
                     "driver": "com.mysql.cj.jdbc.Driver"}))
