--计算客户复购率
WITH first_orders AS (
    SELECT
        ["customer_id"],
        MIN(CAST(["order_purchase_timestamp"] AS DATETIME)) AS first_order_date
    FROM olist_orders_dataset
    WHERE ["order_status"] = 'delivered'
    GROUP BY ["customer_id"]
),
customer_retention AS (
    SELECT
        fo.["customer_id"],
        fo.first_order_date,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM olist_orders_dataset o2 
                WHERE o2.["customer_id"] = fo.["customer_id"]
                AND o2.["order_status"] = 'delivered'
                AND CAST(o2.["order_purchase_timestamp"] AS DATETIME) >= DATEADD(MONTH, 1, fo.first_order_date)
                AND CAST(o2.["order_purchase_timestamp"] AS DATETIME) < DATEADD(MONTH, 2, fo.first_order_date)
            ) THEN 1 
            ELSE 0 
        END AS is_retained
    FROM first_orders fo
)
SELECT
    YEAR(first_order_date) AS cohort_year,
    MONTH(first_order_date) AS cohort_month,
    COUNT(["customer_id"]) AS new_customers,
    SUM(is_retained) AS retained_customers,
    ROUND(CAST(SUM(is_retained) AS FLOAT) / COUNT(["customer_id"]) * 100, 2) AS retention_rate
FROM customer_retention
GROUP BY YEAR(first_order_date), MONTH(first_order_date)
ORDER BY cohort_year, cohort_month;

--计算客户复购率
WITH first_orders AS (
    SELECT
        c.["customer_unique_id"], -- 使用唯一客户ID！
        MIN(CAST(o.["order_purchase_timestamp"] AS DATETIME)) AS first_order_date
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.["customer_id"] = c.["customer_id"] -- 关联客户表以获取唯一ID
    WHERE o.["order_status"] = 'delivered'
    GROUP BY c.["customer_unique_id"]
),
customer_retention AS (
    SELECT
        fo.["customer_unique_id"],
        fo.first_order_date,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM olist_orders_dataset o2 
                JOIN olist_customers_dataset c2 ON o2.["customer_id"] = c2.["customer_id"] -- 内部查询也要关联
                WHERE c2.["customer_unique_id"] = fo.["customer_unique_id"] -- 用唯一ID匹配
                AND o2.["order_status"] = 'delivered'
                AND CAST(o2.["order_purchase_timestamp"] AS DATETIME) > fo.first_order_date -- 只要是第二次购买即可
            ) THEN 1 
            ELSE 0 
        END AS has_repurchased
    FROM first_orders fo
)
SELECT
    COUNT(["customer_unique_id"]) AS total_unique_customers,
    SUM(has_repurchased) AS repurchased_customers,
    ROUND(CAST(SUM(has_repurchased) AS FLOAT) / COUNT(["customer_unique_id"]) * 100, 2) AS overall_repurchase_rate
FROM customer_retention;


-- 检查是否有客户确实有超过1个订单
WITH OrderCounts AS (
    SELECT 
        ["customer_id"], 
        COUNT(*) AS order_count
    FROM olist_orders_dataset
    WHERE ["order_status"] = 'delivered'
    GROUP BY ["customer_id"]
)
SELECT 
    order_count, 
    COUNT(*) AS number_of_customers
FROM OrderCounts
GROUP BY order_count
ORDER BY order_count;

-- 检查是否有客户有多个订单
SELECT ["customer_id"], COUNT(*) as order_count
FROM olist_orders_dataset
WHERE ["order_status"] = 'delivered'
GROUP BY ["customer_id"]
HAVING COUNT(*) > 1
ORDER BY order_count DESC;


WITH CustomerOrderCounts AS (
    SELECT 
        c.["customer_unique_id"], 
        COUNT(DISTINCT o.["order_id"]) AS order_count -- 计算唯一订单数
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.["customer_id"] = o.["customer_id"]
    WHERE o.["order_status"] = 'delivered'
    GROUP BY c.["customer_unique_id"]
)
SELECT 
    order_count, 
    COUNT(*) AS number_of_customers
FROM CustomerOrderCounts
GROUP BY order_count
ORDER BY order_count;

 
 -- 终极简化版：计算“是否有过任何复购”的月度 cohorts
WITH FirstOrders AS (
    -- 找到每个客户的首次购买日期和月份
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
    -- 为每个客户判断是否有过复购（第二次及以上订单）
    SELECT
        c.["customer_unique_id"],
        CASE WHEN COUNT(DISTINCT o.["order_id"]) > 1 THEN 1 ELSE 0 END AS ever_repurchased
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.["customer_id"] = o.["customer_id"]
    WHERE o.["order_status"] = 'delivered'
    GROUP BY c.["customer_unique_id"]
)
-- 将上面两个CTE连接起来，按首购月份汇总
SELECT
    YEAR(fo.first_order_date) AS cohort_year,
    MONTH(fo.first_order_date) AS cohort_month,
    COUNT(fo.["customer_unique_id"]) AS new_customers,
    SUM(rf.ever_repurchased) AS repurchased_customers,
    ROUND(CAST(SUM(rf.ever_repurchased) AS FLOAT) / COUNT(fo.["customer_unique_id"]) * 100, 2) AS repurchase_rate
FROM FirstOrders fo
JOIN RepurchaseFlags rf ON fo.["customer_unique_id"] = rf.["customer_unique_id"]
GROUP BY YEAR(fo.first_order_date), MONTH(fo.first_order_date)
ORDER BY cohort_year, cohort_month;

----------------------------------------------
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