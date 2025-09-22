--月度销售趋势
select format(CAST(o.["order_purchase_timestamp"]AS DATETIME),'yyy--MM')as year_month,
       count(distinct o.["order_id"]) as monthly_orders,
	   round(sum(CAST(p."""payment_value"""AS DECIMAL(10, 2))),2) as monthly_revenue
from olist_orders_dataset as o
join olist_order_payments_dataset as p on o.["order_id"]=p.["order_id"]
where o.["order_status"]='delivered'
group by format(CAST(o.["order_purchase_timestamp"]AS DATETIME),'yyy--MM')
order by year_month