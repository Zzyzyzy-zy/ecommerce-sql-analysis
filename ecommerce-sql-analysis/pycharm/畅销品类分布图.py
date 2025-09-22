import pyodbc
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 连接数据库
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=EcommerceAnalysis;Trusted_Connection=yes;')

sales_trend_query = """
select TOP 10
       t.product_category_name_english as category_name,
	   round(sum(CAST(pay.["payment_value"]AS DECIMAL(10, 2))),2) as revenue,
	   count(distinct ord.["order_id"]) as order_count
from olist_orders_dataset as ord
join olist_order_items_dataset as item on ord.["order_id"]=item.["order_id"]
join olist_products_dataset as prod on item.["product_id"]=prod.["product_id"]
join product_category_name_translation as t on prod.["product_category_name"]=t.product_category_name
join olist_order_payments_dataset as pay on ord.["order_id"]=pay.["order_id"]
where ord.["order_status"]='delivered'
group by t.product_category_name_english
order by revenue DESC
"""
df_category = pd.read_sql(sales_trend_query, conn)
conn.close() # 记得关闭连接
plt.figure(figsize=(12, 6))
sns.barplot(data=df_category, x='revenue', y='category_name', palette='viridis')
plt.title('Top 10 Product Categories by Revenue', fontsize=16)
plt.xlabel('Revenue (R$)')
plt.ylabel('Category')
plt.tight_layout()
plt.savefig('top_categories.png')
plt.show()