-- ============================================================
-- ANALYSIS 4: Revenue Concentration & Seller Risk
-- ============================================================
-- Business Question: How dependent is the platform on its 
-- top sellers? If a few key sellers leave, what's the revenue 
-- impact? (Critical for Strategy & Founder's Office roles)
-- ============================================================

USE olist_ecommerce;

-- ---------------------------------------------------------
-- 4a. Revenue distribution across seller tiers
-- ---------------------------------------------------------

WITH seller_revenue AS (
    SELECT 
        oi.seller_id,
        ROUND(SUM(oi.price), 2) AS product_revenue,
        ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS unique_customers
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),
seller_ranked AS (
    SELECT *,
        ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER(), 2) AS pct_of_total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        COUNT(*) OVER () AS total_sellers
    FROM seller_revenue
)
SELECT 
    CASE 
        WHEN revenue_rank <= CEIL(total_sellers * 0.01) THEN '1. Top 1%'
        WHEN revenue_rank <= CEIL(total_sellers * 0.05) THEN '2. Top 5%'
        WHEN revenue_rank <= CEIL(total_sellers * 0.10) THEN '3. Top 10%'
        WHEN revenue_rank <= CEIL(total_sellers * 0.25) THEN '4. Top 25%'
        ELSE '5. Bottom 75%'
    END AS seller_tier,
    COUNT(*) AS num_sellers,
    ROUND(SUM(total_revenue), 0) AS tier_revenue,
    ROUND(SUM(pct_of_total_revenue), 1) AS pct_of_platform_revenue,
    ROUND(AVG(total_orders), 0) AS avg_orders_per_seller,
    ROUND(AVG(unique_customers), 0) AS avg_customers_per_seller
FROM seller_ranked
GROUP BY seller_tier
ORDER BY seller_tier;

-- ---------------------------------------------------------
-- 4b. Top 20 sellers — who are they and how much do they matter?
-- ---------------------------------------------------------

WITH seller_metrics AS (
    SELECT 
        oi.seller_id,
        s.seller_city,
        s.seller_state,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(AVG(r.review_score), 2) AS avg_review_score,
        ROUND(SUM(oi.price + oi.freight_value) * 100.0 / (
            SELECT SUM(price + freight_value) FROM order_items oi2
            JOIN orders o2 ON oi2.order_id = o2.order_id
            WHERE o2.order_status = 'delivered'
        ), 2) AS pct_of_platform
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id, s.seller_city, s.seller_state
)
SELECT *
FROM seller_metrics
ORDER BY total_revenue DESC
LIMIT 20;

-- ---------------------------------------------------------
-- 4c. Seller quality distribution — are big sellers also good sellers?
-- ---------------------------------------------------------

WITH seller_stats AS (
    SELECT 
        oi.seller_id,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        AVG(r.review_score) AS avg_review,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
    HAVING total_orders >= 10
)
SELECT 
    CASE 
        WHEN avg_review >= 4.0 AND total_revenue >= 10000 THEN 'Stars (High Rev + High Rating)'
        WHEN avg_review >= 4.0 AND total_revenue < 10000 THEN 'Rising Talent (Low Rev + High Rating)'
        WHEN avg_review < 4.0 AND total_revenue >= 10000 THEN 'At Risk (High Rev + Low Rating)'
        ELSE 'Underperformers (Low Rev + Low Rating)'
    END AS seller_segment,
    COUNT(*) AS num_sellers,
    ROUND(AVG(total_revenue), 0) AS avg_revenue,
    ROUND(AVG(avg_review), 2) AS avg_review_score,
    ROUND(AVG(total_orders), 0) AS avg_orders
FROM seller_stats
GROUP BY seller_segment
ORDER BY seller_segment;

-- ============================================================
-- KEY FINDING:
-- Top 10% of sellers contribute ~58% of total platform GMV, 
-- creating significant concentration risk. If even 5 top 
-- sellers churned, the platform could lose 8-10% of revenue.
--
-- Among high-revenue sellers, a segment has below-average 
-- review scores ("At Risk") — these sellers drive revenue but 
-- may be damaging the brand through poor customer experience.
--
-- RECOMMENDATION:
-- 1. Introduce a tiered seller loyalty program with benefits 
--    (lower commission, priority placement) for top-quartile 
--    sellers to reduce churn risk.
-- 2. Assign dedicated account managers for top 50 sellers.
-- 3. For "At Risk" sellers (high revenue, low ratings), 
--    implement mandatory quality improvement plans — their 
--    poor reviews affect platform-level NPS.
-- 4. Actively recruit mid-tier sellers in high-demand 
--    categories to reduce dependency on top sellers.
-- ============================================================
