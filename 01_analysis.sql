-- ============================================
-- OLIST SALES ANALYTICS
-- Author: Vijay Sharma
-- Database: PostgreSQL
-- Dataset: Olist Brazilian E-Commerce
-- Date: 4/2026
-- ============================================



-- ============================================
-- QUERY 1: Total Revenue Overview
-- ============================================
-- Purpose: High level business summary of all
-- delivered orders across the entire dataset
-- ============================================

SELECT
    COUNT(DISTINCT o.order_id)                          AS total_orders,
    COUNT(DISTINCT o.customer_id)                       AS total_customers,
    ROUND(SUM(oi.price)::NUMERIC, 2)                    AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                    AS avg_order_value,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2)            AS total_freight,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_gmv
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Result: 96,478 orders | R$13.2M revenue | R$15.4M GMV | R$119.98 avg order value
-- Insight: Freight = 14.3% of GMV — significant cost optimization opportunity



-- ============================================
-- QUERY 2: Monthly Revenue Trend
-- ============================================
-- Purpose: Show how order volume and revenue
-- grew month by month from 2016 to 2018
-- ============================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    COUNT(DISTINCT o.order_id)                       AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)                 AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY order_month;

-- Result: Growth from 1 order (Sep 2016) to 7,289 orders (Nov 2017)
-- Insight: Clear Black Friday spike in Nov 2017 — highest revenue month



-- ============================================
-- QUERY 3: Revenue by Product Category
-- ============================================
-- Purpose: Identify top performing categories
-- by total revenue and average order value
-- ============================================

SELECT
    COALESCE(ct.product_category_name_english, 'Unknown') AS category,
    COUNT(DISTINCT o.order_id)                             AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)                       AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                       AS avg_price
FROM orders o
JOIN order_items oi  ON o.order_id    = oi.order_id
JOIN products p      ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
                     ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- Result: health_beauty #1 (R$1.23M), watches_gifts #2 (R$1.16M)
-- Insight: Watches has 68% higher avg order value than platform average
--          despite lower order volume — high revenue efficiency category



-- ============================================
-- QUERY 4: Revenue by Customer State
-- ============================================
-- Purpose: Identify geographic revenue
-- concentration across Brazilian states
-- ============================================

SELECT
    c.customer_state                        AS state,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)        AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)        AS avg_order_value
FROM orders o
JOIN order_items oi  ON o.order_id    = oi.order_id
JOIN customers c     ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;

-- Result: SP = 38.3% of all revenue, 3x more than RJ (#2)
-- Insight: SP wins through volume (avg R$109) while smaller states
--          like BA (R$134) show higher order values — untapped premium market



-- ============================================
-- QUERY 5: Top 10 Sellers by Revenue — RANK()
-- ============================================
-- Purpose: Rank sellers by total revenue using
-- window function RANK() OVER()
-- New concept: Window functions
-- ============================================

SELECT
    seller_rank,
    seller_id,
    total_orders,
    total_revenue,
    avg_order_value
FROM (
    SELECT
        s.seller_id,
        COUNT(DISTINCT oi.order_id)               AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2)          AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2)          AS avg_order_value,
        RANK() OVER (ORDER BY SUM(oi.price) DESC) AS seller_rank
    FROM order_items oi
    JOIN sellers s ON oi.seller_id = s.seller_id
    GROUP BY s.seller_id
) ranked_sellers
WHERE seller_rank <= 10;

-- Insight: Top seller revenue vs average seller reveals
--          how concentrated seller performance is