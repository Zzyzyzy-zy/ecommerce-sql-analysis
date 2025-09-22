--畅销商品品类分析
select TOP 10
       t.product_category_name_english as category_name,
	   round(sum(CAST(pay."""payment_value"""AS DECIMAL(10, 2))),2) as revenue,
	   count(distinct ord.["order_id"]) as order_count
from olist_orders_dataset as ord
join olist_order_items_dataset as item on ord.["order_id"]=item.["order_id"]
join olist_products_dataset as prod on item.["product_id"]=prod.["product_id"]
join product_category_name_translation as t on prod.["product_category_name"]=t.product_category_name
join olist_order_payments_dataset as pay on ord.["order_id"]=pay.["order_id"]
where ord.["order_status"]='delivered'
group by t.product_category_name_english
order by revenue DESC