-- 终极简化版：计算“是否有过任何复购”的月度 cohorts + 总计行
WITH FirstOrders AS (
    SELECT
        c.["customer_unique_id"],
        MIN(CAST(o.["order_purchase_timestamp"] AS DATETIME)) AS first_order_date,
        FORMAT(MIN(CAST(o.["order_purchase_timestamp"] AS DATETIME)), 'yyyy-MM') AS cohort_month
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.["customer_id"] = c.["customer_id"]
    WHERE o.["order_status"] = 'delivered'
    GROUP BY c.["customer_unique_id"]
),
RepurchaseFlags AS (
    SELECT
        c.["customer_unique_id"],
        CASE WHEN COUNT(DISTINCT o.["order_id"]) > 1 THEN 1 ELSE 0 END AS ever_repurchased
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.["customer_id"] = o.["customer_id"]
    WHERE o.["order_status"] = 'delivered'
    GROUP BY c.["customer_unique_id"]
),
MonthlyCohorts AS (
    SELECT
        YEAR(fo.first_order_date) AS cohort_year,
        MONTH(fo.first_order_date) AS cohort_month,
        COUNT(fo.["customer_unique_id"]) AS new_customers,
        SUM(rf.ever_repurchased) AS repurchased_customers,
        ROUND(CAST(SUM(rf.ever_repurchased) AS FLOAT) / COUNT(fo.["customer_unique_id"]) * 100, 2) AS repurchase_rate
    FROM FirstOrders fo
    JOIN RepurchaseFlags rf ON fo.["customer_unique_id"] = rf.["customer_unique_id"]
    GROUP BY YEAR(fo.first_order_date), MONTH(fo.first_order_date)
)
-- 首先查询按月分组的结果
SELECT 
    cohort_year,
    cohort_month,
    new_customers,
    repurchased_customers,
    repurchase_rate
FROM MonthlyCohorts

UNION ALL -- 合并总计行

-- 然后计算总计行
SELECT 
    NULL AS cohort_year, -- 总计行没有年份
    NULL AS cohort_month, -- 总计行没有月份
    SUM(new_customers) AS total_customers,
    SUM(repurchased_customers) AS total_repurchased,
    ROUND(CAST(SUM(repurchased_customers) AS FLOAT) / SUM(new_customers) * 100, 2) AS overall_repurchase_rate
FROM MonthlyCohorts

ORDER BY cohort_year, cohort_month; -- 排序会让总计行显示在最后