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