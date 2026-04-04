-- ============================================================
-- ANALYSIS 3: Late vs. On-Time Delivery — Broken Promises
-- ============================================================
-- Business Question: What hurts more — slow delivery or 
-- missing the promised delivery date? How should we set 
-- delivery estimates?
-- ============================================================

USE olist_ecommerce;

-- ---------------------------------------------------------
-- 3a. On-time vs. late delivery impact on reviews
-- ---------------------------------------------------------

SELECT 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN '1. On Time / Early'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) BETWEEN 1 AND 7 THEN '2. Late by 1-7 days'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) BETWEEN 8 AND 14 THEN '3. Late by 8-14 days'
        ELSE '4. Late by 15+ days'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_negative_reviews,
    ROUND(SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_positive_reviews
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status
ORDER BY delivery_status;

-- ---------------------------------------------------------
-- 3b. How accurate are current delivery estimates?
-- ---------------------------------------------------------

SELECT 
    CASE 
        WHEN DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) > 14 THEN 'Over-estimated by 14+ days'
        WHEN DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) BETWEEN 7 AND 14 THEN 'Over-estimated by 7-14 days'
        WHEN DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) BETWEEN 1 AND 6 THEN 'Over-estimated by 1-6 days'
        WHEN DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) = 0 THEN 'Exactly on time'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) BETWEEN 1 AND 7 THEN 'Under-estimated by 1-7 days'
        ELSE 'Under-estimated by 7+ days'
    END AS estimate_accuracy,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM orders 
        WHERE order_status = 'delivered' 
        AND order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
    ), 1) AS pct_of_total,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY estimate_accuracy
ORDER BY avg_review_score DESC;

-- ---------------------------------------------------------
-- 3c. Does early delivery boost satisfaction?
-- ---------------------------------------------------------

SELECT 
    CASE 
        WHEN DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) >= 15 THEN 'Delivered 15+ days early'
        WHEN DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) BETWEEN 8 AND 14 THEN 'Delivered 8-14 days early'
        WHEN DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) BETWEEN 1 AND 7 THEN 'Delivered 1-7 days early'
        ELSE 'Delivered on time or late'
    END AS early_delivery_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_5_star
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
GROUP BY early_delivery_bucket
ORDER BY early_delivery_bucket;

-- ============================================================
-- KEY FINDING:
-- On-time deliveries averaged ~4.2★ while orders late by 15+ 
-- days dropped to ~1.8★. Critically, the jump from "late by 
-- 1-7 days" to "late by 15+ days" was far more damaging than 
-- the difference between fast and slow on-time deliveries.
--
-- Customers tolerate slow delivery if expectations were set 
-- correctly, but broken promises trigger disproportionate 
-- negative reactions.
--
-- Early deliveries (8+ days ahead of estimate) scored highest,
-- suggesting customers experience genuine delight when orders 
-- arrive much earlier than expected.
--
-- RECOMMENDATION:
-- Pad delivery estimates by 3-5 days to under-promise and 
-- over-deliver. The satisfaction boost from "arriving early" 
-- far outweighs the marginal cost of quoting a longer window.
-- For orders at risk of missing the estimate, trigger a 
-- proactive apology + discount before the customer notices.
-- ============================================================
