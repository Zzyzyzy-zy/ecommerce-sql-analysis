create database EcommerceAnalysis;
go
-- 查看每个表结构
use EcommerceAnalysis
select*
from olist_customers_dataset
select*
from olist_order_items_dataset
select*
from olist_order_payments_dataset
select*
from olist_orders_dataset
SELECT*
FROM olist_products_dataset
SELECT*
FROM product_category_name_translation
--查看各表数据量
select 'order_id',count(*)as row_count
from olist_orders_dataset
union all
select 'customer_id',count(*)
from olist_customers_dataset
union all
select 'order_item_id',count(*)
from olist_order_items_dataset
union all
select 'payment_sequential',count(*)
from olist_order_payments_dataset
union all
select 'product_id',count(*)
from olist_products_dataset
--查看订单状态分布
select """order_status""",count(*)as ordercount
from olist_orders_dataset
group by """order_status"""
order by  ordercount Desc
--查看支付类型分布
select """payment_type""",count(*)as typecount
from olist_order_payments_dataset
group by """payment_type"""
order by typecount DESC
--查看时间范围
select min("""order_purchase_timestamp""") as earilest_order,max("""order_purchase_timestamp""") as latest_order
from olist_orders_dataset



