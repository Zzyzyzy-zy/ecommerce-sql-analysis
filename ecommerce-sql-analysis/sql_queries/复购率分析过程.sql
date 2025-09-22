--����ͻ�������
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

--����ͻ�������
WITH first_orders AS (
    SELECT
        c.["customer_unique_id"], -- ʹ��Ψһ�ͻ�ID��
        MIN(CAST(o.["order_purchase_timestamp"] AS DATETIME)) AS first_order_date
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.["customer_id"] = c.["customer_id"] -- �����ͻ����Ի�ȡΨһID
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
                JOIN olist_customers_dataset c2 ON o2.["customer_id"] = c2.["customer_id"] -- �ڲ���ѯҲҪ����
                WHERE c2.["customer_unique_id"] = fo.["customer_unique_id"] -- ��ΨһIDƥ��
                AND o2.["order_status"] = 'delivered'
                AND CAST(o2.["order_purchase_timestamp"] AS DATETIME) > fo.first_order_date -- ֻҪ�ǵڶ��ι��򼴿�
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


-- ����Ƿ��пͻ�ȷʵ�г���1������
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

-- ����Ƿ��пͻ��ж������
SELECT ["customer_id"], COUNT(*) as order_count
FROM olist_orders_dataset
WHERE ["order_status"] = 'delivered'
GROUP BY ["customer_id"]
HAVING COUNT(*) > 1
ORDER BY order_count DESC;


WITH CustomerOrderCounts AS (
    SELECT 
        c.["customer_unique_id"], 
        COUNT(DISTINCT o.["order_id"]) AS order_count -- ����Ψһ������
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

 
 -- �ռ��򻯰棺���㡰�Ƿ��й��κθ��������¶� cohorts
WITH FirstOrders AS (
    -- �ҵ�ÿ���ͻ����״ι������ں��·�
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
    -- Ϊÿ���ͻ��ж��Ƿ��й��������ڶ��μ����϶�����
    SELECT
        c.["customer_unique_id"],
        CASE WHEN COUNT(DISTINCT o.["order_id"]) > 1 THEN 1 ELSE 0 END AS ever_repurchased
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.["customer_id"] = o.["customer_id"]
    WHERE o.["order_status"] = 'delivered'
    GROUP BY c.["customer_unique_id"]
)
-- ����������CTE�������������׹��·ݻ���
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
-- �ռ��򻯰棺���㡰�Ƿ��й��κθ��������¶� cohorts + �ܼ���
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
-- ���Ȳ�ѯ���·���Ľ��
SELECT 
    cohort_year,
    cohort_month,
    new_customers,
    repurchased_customers,
    repurchase_rate
FROM MonthlyCohorts

UNION ALL -- �ϲ��ܼ���

-- Ȼ������ܼ���
SELECT 
    NULL AS cohort_year, -- �ܼ���û�����
    NULL AS cohort_month, -- �ܼ���û���·�
    SUM(new_customers) AS total_customers,
    SUM(repurchased_customers) AS total_repurchased,
    ROUND(CAST(SUM(repurchased_customers) AS FLOAT) / SUM(new_customers) * 100, 2) AS overall_repurchase_rate
FROM MonthlyCohorts

ORDER BY cohort_year, cohort_month; -- ��������ܼ�����ʾ�����