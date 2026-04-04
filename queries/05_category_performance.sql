-- ============================================================
-- ANALYSIS 5: Product Category Performance & Opportunity Mapping
-- ============================================================
-- Business Question: Which product categories should we 
-- double down on? Where are the underexplored opportunities?
-- ============================================================

USE olist_ecommerce;

-- ---------------------------------------------------------
-- 5a. Top 20 categories by revenue with satisfaction scores
-- ---------------------------------------------------------

SELECT 
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 0) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_order_value,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_positive_reviews,
    COUNT(DISTINCT oi.seller_id) AS active_sellers
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN orders o ON oi.order_id = o.order_id
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
HAVING total_orders >= 50
ORDER BY total_revenue DESC
LIMIT 20;

-- ---------------------------------------------------------
-- 5b. Category opportunity matrix: AOV vs. Satisfaction
-- Identifies high-value, high-satisfaction categories that
-- may be underexplored growth opportunities
-- ---------------------------------------------------------

WITH category_stats AS (
    SELECT 
        COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(SUM(oi.price), 0) AS total_revenue,
        ROUND(AVG(oi.price), 2) AS avg_order_value,
        ROUND(AVG(r.review_score), 2) AS avg_review_score
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
    JOIN orders o ON oi.order_id = o.order_id
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY category
    HAVING total_orders >= 30
)
SELECT 
    category,
    total_orders,
    total_revenue,
    avg_order_value,
    avg_review_score,
    CASE 
        WHEN avg_order_value >= 150 AND avg_review_score >= 4.0 THEN '★ HIGH OPPORTUNITY (High AOV + High Satisfaction)'
        WHEN avg_order_value >= 150 AND avg_review_score < 4.0 THEN '⚠ FIX QUALITY (High AOV but Low Satisfaction)'
        WHEN avg_order_value < 150 AND avg_review_score >= 4.0 THEN '→ VOLUME PLAY (Low AOV but High Satisfaction)'
        ELSE '✗ DEPRIORITIZE (Low AOV + Low Satisfaction)'
    END AS strategic_quadrant
FROM category_stats
ORDER BY avg_order_value DESC;

-- ---------------------------------------------------------
-- 5c. Category growth trends (quarter over quarter)
-- ---------------------------------------------------------

SELECT 
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    CONCAT(YEAR(o.order_purchase_timestamp), '-Q', QUARTER(o.order_purchase_timestamp)) AS quarter,
    COUNT(DISTINCT oi.order_id) AS quarterly_orders,
    ROUND(SUM(oi.price), 0) AS quarterly_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND COALESCE(ct.product_category_name_english, p.product_category_name) IN (
      -- Top 10 categories by revenue
      SELECT category FROM (
          SELECT COALESCE(ct2.product_category_name_english, p2.product_category_name) AS category,
                 SUM(oi2.price) AS rev
          FROM order_items oi2
          JOIN products p2 ON oi2.product_id = p2.product_id
          LEFT JOIN category_translation ct2 ON p2.product_category_name = ct2.product_category_name
          JOIN orders o2 ON oi2.order_id = o2.order_id
          WHERE o2.order_status = 'delivered'
          GROUP BY category
          ORDER BY rev DESC
          LIMIT 10
      ) top_cats
  )
GROUP BY category, quarter
ORDER BY category, quarter;

-- ============================================================
-- KEY FINDING:
-- Bed/Bath/Table and Health/Beauty dominate revenue but with 
-- moderate review scores (~4.0). Categories like Watches and 
-- Computers show significantly higher AOV (R$200+) with 
-- comparable or better satisfaction — these are underexplored 
-- high-margin growth opportunities.
--
-- Several high-AOV categories have low satisfaction scores, 
-- indicating quality/fulfillment issues that, if fixed, could 
-- unlock substantial revenue.
--
-- RECOMMENDATION:
-- 1. Increase seller acquisition in "High Opportunity" 
--    categories (high AOV + high satisfaction) like Watches 
--    and Electronics to improve blended platform margins.
-- 2. For "Fix Quality" categories, investigate whether low 
--    scores stem from product issues or delivery problems 
--    (heavier items = slower shipping).
-- 3. For top volume categories, introduce bundles and 
--    cross-sell recommendations to increase basket size.
-- ============================================================
