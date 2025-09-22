# 巴西电商数据分析项目 (Brazilian E-Commerce Data Analysis)

## 📊 项目概述
本项目基于 Olist 提供的巴西电商公开数据集，使用 **SQL Server** 进行数据清洗、查询与深度分析，并利用 **Python** 及相关可视化库进行数据可视化，旨在挖掘销售业绩、客户行为与商品表现背后的关键洞察，为业务决策提供数据支持。

## 🛠️ 技术栈
- **数据库**: Microsoft SQL Server
- **编程语言**: Python
- **核心库**: pandas, matplotlib, seaborn, pyodbc
- **工具**: SQL Server Management Studio (SSMS), pycharm
- **技能**: 复杂SQL查询（多表连接、CTE、窗口函数）、数据可视化、业务分析报告撰写

## 📁 项目结构
```
ecommerce-sql-analysis/
├── DATA files/
│   ├── olist_customers_dataset.csv          # 客户数据集
│   ├── olist_order_items_dataset.csv        # 订单商品数据集
│   ├── olist_order_payments_dataset.csv     # 订单支付数据集
│   ├── olist_orders_dataset.csv             # 订单数据集
│   ├── olist_products_dataset.csv           # 商品数据集
│   └── product_category_name_translation.csv # 商品类别名称翻译
├── sql_queries/
│   ├── 数据基本情况.sql                      # 数据库设置和基础探索
│   ├── 总体kpi查询.sql                       # 整体业务KPI指标
│   ├── 销售趋势查询.sql                      # 销售趋势分析
│   ├── 畅销品类查询.sql                      # 按收入排名的产品类别
│   ├── 复购率分析过程.sql                    # 复购率分析过程
│   └── 复购率分析查询-最终版.sql              # 最终版复购率分析
├── pycharm/
│   ├── 销售趋势.py                          # 销售趋势可视化
│   ├── 畅销品类分布图.py                     # 畅销品类可视化
│   └── top_categories.png                   # 生成的可视化图表
│   └── sales_trend.png                   # 生成的可视化图表
├── README.md```

## 🔍 核心发现与洞察
通过分析，发现了影响业务增长的几个关键点：

1.  **客户留存危机**：**用户复购率极低（整体仅3%）**，且自2017年中起呈现**断崖式下跌**趋势，至2018年8月已降至**0.55%**。这表明平台的客户忠诚度体系和留存策略可能存在严重问题。
2.  **销售趋势**：销售额在2017年第四季度和2018年第一季度达到峰值，表明年末节日和促销活动对拉动销售效果显著。
3.  **商品表现**：`床浴用品`、`健康美容` 和 `运动休闲` 是销售额最高的三大核心品类，应作为运营重点。
4.  **支付方式**：信用卡是客户最常用的支付方式，占比超过70%。

## 🚀 如何运行本项目
1.  **克隆本仓库** (Clone this repository):
    ```bash
    git clone https://github.com/Zzyzyzy-zy/ecommerce-sql-analysis.git
    ```
2.**配置环境**：确保本地已安装SQL Server和Python环境及所需库（pandas。matplotlib等）
3.  **运行SQL脚本**：按顺序执行 `sql_queries/` 目录下的 `.sql` 文件，即可在 SQL Server 中复现全部分析过程。
4.  **运行pycharm**：打开 `python/` 目录下的 python 文件，运行所有代码即可复现所有数据可视化图表。

## 📈 代码示例 (复购率分析查询)
```sql
-- 使用CTE和EXISTS计算复购客户数
-- 终极简化版：计算“是否有过任何复购”的月度 cohorts + 总计行
WITH FirstOrders AS (
    SELECT
        c.customer_unique_id,
        MIN(CAST(o.order_purchase_timestamp AS DATETIME)) AS first_order_date,
        FORMAT(MIN(CAST(o.order_purchase_timestamp AS DATETIME)), 'yyyy-MM') AS cohort_month
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
RepurchaseFlags AS (
    SELECT
        c.customer_unique_id,
        CASE WHEN COUNT(DISTINCT o.order_id) > 1 THEN 1 ELSE 0 END AS ever_repurchased
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
MonthlyCohorts AS (
    SELECT
        YEAR(fo.first_order_date) AS cohort_year,
        MONTH(fo.first_order_date) AS cohort_month,
        COUNT(fo.customer_unique_id) AS new_customers,
        SUM(rf.ever_repurchased) AS repurchased_customers,
        ROUND(CAST(SUM(rf.ever_repurchased) AS FLOAT) / COUNT(fo.customer_unique_id) * 100, 2) AS repurchase_rate
    FROM FirstOrders fo
    JOIN RepurchaseFlags rf ON fo.customer_unique_id = rf.customer_unique_id
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

ORDER BY cohort_year, cohort_month; -- 排序会让总计行显示在最后```


## 💡 遇到的问题与解决方案
- **问题一：复购率查询初始结果为0**
  - **原因**：错误地使用了代表一次购买的 `customer_id` 而非代表一个客户的 `customer_unique_id`。
  - **解决**：通过查阅数据集字典并关联 `olist_customers_dataset` 表获得唯一客户标识，成功计算出正确的复购率。
- **问题二：时间窗口定义过于严格**
  - **原因**：最初要求客户在首购后精确的自然月内复购，条件过于苛刻。
  - **解决**：改用“是否有过任何第二次购买”的宽松且合理的定义来计算复购率。 