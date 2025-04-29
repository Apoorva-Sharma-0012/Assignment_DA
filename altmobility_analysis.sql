
-- 1. Order and Sales Analysis
-- A. Order Status Distribution
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_amount), 2) AS total_revenue
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- B. Monthly Sales Trend
SELECT 
    strftime('%Y-%m', order_date) AS order_month,
    ROUND(SUM(order_amount), 2) AS total_sales
FROM orders
GROUP BY order_month
ORDER BY order_month;

-- 2. Customer Analysis
-- A. Unique, Repeat, and One-time Customers
SELECT COUNT(DISTINCT customer_id) AS unique_customers FROM orders;

SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(*) > 1
);

SELECT COUNT(*) AS one_time_customers
FROM (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(*) = 1
);

-- B. Monthly New vs Returning Customers
WITH FirstOrder AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
),
OrderWithFlag AS (
    SELECT 
        o.*,
        CASE 
            WHEN o.order_date = f.first_order_date THEN 'New'
            ELSE 'Returning'
        END AS customer_type
    FROM orders o
    JOIN FirstOrder f ON o.customer_id = f.customer_id
)
SELECT 
    strftime('%Y-%m', order_date) AS order_month,
    customer_type,
    COUNT(DISTINCT customer_id) AS customer_count
FROM OrderWithFlag
GROUP BY order_month, customer_type
ORDER BY order_month;

-- 3. Payment Status Analysis
-- A. Payment Status Distribution
SELECT 
    payment_status,
    COUNT(*) AS total_payments
FROM payments
GROUP BY payment_status;

-- B. Monthly Success/Failure Breakdown
SELECT 
    strftime('%Y-%m', payment_date) AS payment_month,
    SUM(CASE WHEN payment_status = 'completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN payment_status = 'pending' THEN 1 ELSE 0 END) AS pending,
    ROUND(
        1.0 * SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN payment_status IN ('failed', 'completed') THEN 1 ELSE 0 END), 0),
        2
    ) AS failure_rate
FROM payments
GROUP BY payment_month
ORDER BY payment_month;

-- 4. Order Details Report
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_amount,
    o.order_status,
    p.payment_date,
    p.payment_amount,
    p.payment_method,
    p.payment_status
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
ORDER BY o.order_date;
