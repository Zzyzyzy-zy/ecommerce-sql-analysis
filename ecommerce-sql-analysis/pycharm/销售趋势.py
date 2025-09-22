import pyodbc
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 连接数据库
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=EcommerceAnalysis;Trusted_Connection=yes;')

# 将上面‘分析2’的SQL语句作为字符串写入
sales_trend_query = """
select format(CAST(o.["order_purchase_timestamp"]AS DATETIME),'yyy--MM')as year_month,
       count(distinct o.["order_id"]) as monthly_orders,
	   round(sum(CAST(p.["payment_value"]AS DECIMAL(10, 2))),2) as monthly_revenue
from olist_orders_dataset as o
join olist_order_payments_dataset as p on o.["order_id"]=p.["order_id"]
where o.["order_status"]='delivered'
group by format(CAST(o.["order_purchase_timestamp"]AS DATETIME),'yyy--MM')
order by year_month
"""
df_sales_trend = pd.read_sql(sales_trend_query, conn)
conn.close() # 记得关闭连接
plt.figure(figsize=(14, 6))
plt.plot(df_sales_trend['year_month'], df_sales_trend['monthly_revenue'], marker='o', linewidth=2)
plt.title('Monthly Sales Revenue Trend', fontsize=16, fontweight='bold')
plt.xlabel('Month')
plt.ylabel('Revenue (R$)')
plt.xticks(rotation=45)
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig('sales_trend.png') # 保存图片，用于你的报告
plt.show()