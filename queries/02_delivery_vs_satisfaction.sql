-- ============================================================
-- ANALYSIS 2: Delivery Time Impact on Customer Satisfaction
-- ============================================================
-- Business Question: How does delivery speed affect review 
-- scores? Is there a specific threshold where satisfaction 
-- drops off a cliff?
-- ============================================================

USE olist_ecommerce;

-- ---------------------------------------------------------
-- 2a. Delivery time buckets vs. average review scores
-- ---------------------------------------------------------

SELECT 
    CASE 
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 7 THEN '01: 0-7 days'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 14 THEN '02: 8-14 days'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 21 THEN '03: 15-21 days'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 30 THEN '04: 22-30 days'
        ELSE '05: 30+ days'
    END AS delivery_window,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_1_star,
    ROUND(SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_5_star
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_window
ORDER BY delivery_window;

-- ---------------------------------------------------------
-- 2b. Average delivery time by customer state (geographic view)
-- ---------------------------------------------------------

SELECT 
    c.customer_state,
    COUNT(*) AS total_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING total_orders >= 100
ORDER BY avg_delivery_days DESC;

-- ---------------------------------------------------------
-- 2c. Delivery time distribution (for histogram visualization)
-- ---------------------------------------------------------

SELECT 
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,
    COUNT(*) AS order_count,
    ROUND(AVG(r.review_score), 2) AS avg_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) BETWEEN 1 AND 60
GROUP BY delivery_days
ORDER BY delivery_days;

-- ============================================================
-- KEY FINDING:
-- Orders delivered within 7 days averaged ~4.3★ with only ~5% 
-- 1-star reviews. Beyond 21 days, the average dropped to ~2.5★ 
-- with 40%+ 1-star rates. The satisfaction cliff hits hard 
-- between day 14 and day 21.
--
-- States farther from major logistics hubs (like SP) experience
-- significantly longer delivery times and lower satisfaction.
--
-- RECOMMENDATION:
-- Set a proactive customer notification trigger at day 12 
-- post-purchase. Offer estimated delivery updates and, for 
-- orders likely to exceed 21 days, provide a small credit or 
-- discount code proactively — preventing 1-star reviews is 
-- cheaper than acquiring a new customer.
-- ============================================================
