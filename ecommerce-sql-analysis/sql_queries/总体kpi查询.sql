--×ÜÌåÒµ¼¨kpi
select count(distinct o."""order_id""") as total_orders,
       count(distinct o.["customer_id"]) as total_customers,
	   round(sum(CAST(p."""payment_value"""AS DECIMAL(10, 2))),2) as total_revenue,
	   round(sum(CAST(p."""payment_value"""AS DECIMAL(10, 2)))/count(distinct o.["order_id"]),2) as avg_order_value
from olist_orders_dataset as o
join olist_order_payments_dataset as p on o.["order_id"]=p.["order_id"]
where o.["order_status"]='delivered'