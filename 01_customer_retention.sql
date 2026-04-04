-- ============================================================
-- ANALYSIS 1: Customer Retention & Repeat Purchase Behavior
-- ============================================================
-- Business Question: What percentage of customers come back
-- for a second purchase? How does our retention look?
-- ============================================================

USE olist_ecommerce;

-- ---------------------------------------------------------
-- 1a. Repeat purchase distribution
-- customer_unique_id = actual person (customer_id changes per order)
-- ---------------------------------------------------------

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        MIN(o.order_purchase_timestamp) AS first_order_date,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        DATEDIFF(
            MAX(o.order_purchase_timestamp), 
            MIN(o.order_purchase_timestamp)
        ) AS days_between_first_last
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    total_orders AS orders_placed,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_orders), 2) AS pct_of_total
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;

-- ---------------------------------------------------------
-- 1b. Retention summary: one-time vs. repeat buyers
-- ---------------------------------------------------------

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(p.payment_value), 2) AS lifetime_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE WHEN total_orders = 1 THEN 'One-Time Buyer' ELSE 'Repeat Buyer' END AS customer_type,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_orders), 2) AS pct_of_customers,
    ROUND(AVG(lifetime_value), 2) AS avg_lifetime_value,
    ROUND(SUM(lifetime_value), 0) AS total_revenue_contribution
FROM customer_orders
GROUP BY customer_type;

-- ---------------------------------------------------------
-- 1c. Time gap between repeat purchases (for repeat buyers)
-- ---------------------------------------------------------

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp
        ) AS order_num
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
repeat_buyers AS (
    SELECT 
        a.customer_unique_id,
        DATEDIFF(b.order_purchase_timestamp, a.order_purchase_timestamp) AS days_to_second_order
    FROM customer_orders a
    JOIN customer_orders b 
        ON a.customer_unique_id = b.customer_unique_id
        AND a.order_num = 1 AND b.order_num = 2
)
SELECT 
    CASE 
        WHEN days_to_second_order <= 30 THEN '0-30 days'
        WHEN days_to_second_order <= 60 THEN '31-60 days'
        WHEN days_to_second_order <= 90 THEN '61-90 days'
        WHEN days_to_second_order <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END AS time_to_repeat,
    COUNT(*) AS num_customers,
    ROUND(AVG(days_to_second_order), 0) AS avg_days
FROM repeat_buyers
GROUP BY time_to_repeat
ORDER BY FIELD(time_to_repeat, '0-30 days', '31-60 days', '61-90 days', '91-180 days', '180+ days');

-- ============================================================
-- KEY FINDING:
-- ~97% of customers are one-time buyers — severe retention gap.
-- Repeat buyers have ~2.8x higher lifetime value than one-timers.
-- Among repeat buyers, majority return within 30-90 days.
--
-- RECOMMENDATION:
-- Implement post-purchase email flows with personalized product 
-- recommendations within 7 days of delivery. Introduce a 
-- first-repeat-purchase discount (e.g., 10% off next order 
-- within 60 days) to reduce the reactivation barrier. The 
-- 30-90 day window is the critical retention window to target.
-- ============================================================
