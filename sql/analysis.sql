-- ============================================================
-- E-COMMERCE SALES ANALYTICS USING DUCKDB
-- SQL Analysis
-- ============================================================


-- ============================================================
-- 1. DATA VALIDATION
-- ============================================================

-- Check total number of records
SELECT
    COUNT(*) AS total_rows
FROM clean_orders;


-- Check number of unique orders
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM clean_orders;


-- Check for missing important values
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(order_id) AS missing_order_id,
    COUNT(*) - COUNT(ordered_at) AS missing_order_date,
    COUNT(*) - COUNT(customer_id) AS missing_customer_id,
    COUNT(*) - COUNT(net_revenue) AS missing_net_revenue
FROM clean_orders;


-- ============================================================
-- 2. BASIC SALES METRICS
-- ============================================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units_sold,
    ROUND(SUM(gross_payment), 2) AS gross_sales,
    ROUND(SUM(refund_amount), 2) AS total_refunds,
    ROUND(SUM(net_revenue), 2) AS net_revenue,
    ROUND(
        SUM(net_revenue) / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM clean_orders;


-- ============================================================
-- 3. ORDER STATUS ANALYSIS
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS number_of_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM clean_orders
GROUP BY order_status
ORDER BY number_of_orders DESC;


-- ============================================================
-- 4. CUSTOMER ANALYSIS
-- ============================================================

SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units,
    ROUND(SUM(net_revenue), 2) AS total_revenue,
    ROUND(
        SUM(net_revenue) /
        COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM clean_orders
GROUP BY customer_id
ORDER BY total_revenue DESC;


-- Top 10 customers
SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS orders,
    SUM(units) AS units,
    ROUND(SUM(net_revenue), 2) AS revenue
FROM clean_orders
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 5. CUSTOMER SEGMENT ANALYSIS
-- ============================================================

SELECT
    customer_segment,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units,
    ROUND(SUM(gross_payment), 2) AS gross_revenue,
    ROUND(SUM(refund_amount), 2) AS refunds,
    ROUND(SUM(net_revenue), 2) AS net_revenue,
    ROUND(
        SUM(net_revenue) /
        COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM clean_orders
GROUP BY customer_segment
ORDER BY net_revenue DESC;


-- ============================================================
-- 6. ACQUISITION CHANNEL ANALYSIS
-- ============================================================

SELECT
    acquisition_channel,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units,
    ROUND(SUM(gross_payment), 2) AS gross_revenue,
    ROUND(SUM(refund_amount), 2) AS refunds,
    ROUND(SUM(net_revenue), 2) AS net_revenue,
    ROUND(
        SUM(net_revenue) /
        COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM clean_orders
GROUP BY acquisition_channel
ORDER BY net_revenue DESC;


-- ============================================================
-- 7. COUNTRY ANALYSIS
-- ============================================================

SELECT
    country_code,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units,
    ROUND(SUM(gross_payment), 2) AS gross_revenue,
    ROUND(SUM(refund_amount), 2) AS refunds,
    ROUND(SUM(net_revenue), 2) AS net_revenue
FROM clean_orders
GROUP BY country_code
ORDER BY net_revenue DESC;


-- ============================================================
-- 8. MONTHLY SALES ANALYSIS
-- ============================================================

SELECT
    DATE_TRUNC('month', ordered_at) AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units,
    ROUND(SUM(net_revenue), 2) AS revenue
FROM clean_orders
WHERE ordered_at IS NOT NULL
GROUP BY month
ORDER BY month;


-- ============================================================
-- 9. MONTHLY REVENUE GROWTH
-- ============================================================

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', ordered_at) AS month,
        SUM(net_revenue) AS revenue
    FROM clean_orders
    WHERE ordered_at IS NOT NULL
    GROUP BY month
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,

    ROUND(
        LAG(revenue) OVER (ORDER BY month),
        2
    ) AS previous_month_revenue,

    ROUND(
        (
            (
                revenue -
                LAG(revenue) OVER (ORDER BY month)
            )
            /
            NULLIF(
                LAG(revenue) OVER (ORDER BY month),
                0
            )
        ) * 100,
        2
    ) AS growth_percentage

FROM monthly
ORDER BY month;


-- ============================================================
-- 10. BEST AND LOWEST REVENUE MONTH
-- ============================================================

-- Best month
SELECT
    DATE_TRUNC('month', ordered_at) AS month,
    ROUND(SUM(net_revenue), 2) AS revenue
FROM clean_orders
WHERE ordered_at IS NOT NULL
GROUP BY month
ORDER BY revenue DESC
LIMIT 1;


-- Lowest month
SELECT
    DATE_TRUNC('month', ordered_at) AS month,
    ROUND(SUM(net_revenue), 2) AS revenue
FROM clean_orders
WHERE ordered_at IS NOT NULL
GROUP BY month
ORDER BY revenue ASC
LIMIT 1;


-- ============================================================
-- 11. REFUND ANALYSIS
-- ============================================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,

    COUNT(
        DISTINCT CASE
            WHEN refund_amount > 0
            THEN order_id
        END
    ) AS refunded_orders,

    ROUND(SUM(refund_amount), 2) AS total_refunds,

    ROUND(SUM(gross_payment), 2) AS gross_payment,

    ROUND(
        SUM(refund_amount) * 100.0 /
        NULLIF(SUM(gross_payment), 0),
        2
    ) AS refund_rate_percentage

FROM clean_orders;


-- Refund analysis by customer segment
SELECT
    customer_segment,
    ROUND(SUM(gross_payment), 2) AS gross_revenue,
    ROUND(SUM(refund_amount), 2) AS refunds,
    ROUND(
        SUM(refund_amount) * 100.0 /
        NULLIF(SUM(gross_payment), 0),
        2
    ) AS refund_rate
FROM clean_orders
GROUP BY customer_segment
ORDER BY refund_rate DESC;


-- ============================================================
-- 12. CREATE CUSTOMER SUMMARY TABLE
-- ============================================================

CREATE OR REPLACE TABLE customer_summary AS

SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units,
    ROUND(SUM(gross_payment), 2) AS gross_spending,
    ROUND(SUM(refund_amount), 2) AS total_refunds,
    ROUND(SUM(net_revenue), 2) AS net_spending

FROM clean_orders

GROUP BY customer_id;


-- ============================================================
-- 13. INNER JOIN ANALYSIS
-- ============================================================

SELECT
    o.order_id,
    o.ordered_at,
    o.customer_id,
    o.country_code,
    o.customer_segment,
    o.net_revenue,

    c.total_orders AS customer_total_orders,
    c.net_spending AS customer_total_spending

FROM clean_orders o

INNER JOIN customer_summary c
    ON o.customer_id = c.customer_id

LIMIT 20;


-- ============================================================
-- 14. CUSTOMER VALUE ANALYSIS USING JOIN
-- ============================================================

SELECT
    o.customer_id,
    c.total_orders,
    c.total_units,
    c.gross_spending,
    c.total_refunds,
    c.net_spending,

    ROUND(
        c.total_refunds * 100.0 /
        NULLIF(c.gross_spending, 0),
        2
    ) AS refund_rate

FROM clean_orders o

INNER JOIN customer_summary c
    ON o.customer_id = c.customer_id

GROUP BY
    o.customer_id,
    c.total_orders,
    c.total_units,
    c.gross_spending,
    c.total_refunds,
    c.net_spending

ORDER BY c.net_spending DESC

LIMIT 20;


-- ============================================================
-- 15. COUNTRY SUMMARY TABLE
-- ============================================================

CREATE OR REPLACE TABLE country_summary AS

SELECT
    country_code,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(units) AS total_units,
    ROUND(SUM(net_revenue), 2) AS total_revenue

FROM clean_orders

GROUP BY country_code;


-- ============================================================
-- 16. COUNTRY JOIN ANALYSIS
-- ============================================================

SELECT
    o.order_id,
    o.customer_id,
    o.country_code,
    o.net_revenue,

    c.total_orders AS country_orders,
    c.total_units AS country_units,
    c.total_revenue AS country_revenue

FROM clean_orders o

INNER JOIN country_summary c
    ON o.country_code = c.country_code

LIMIT 20;


-- ============================================================
-- 17. CUSTOMER RANKING
-- ============================================================

SELECT
    customer_id,
    total_orders,
    total_units,
    net_spending,

    RANK() OVER (
        ORDER BY net_spending DESC
    ) AS revenue_rank

FROM customer_summary

ORDER BY revenue_rank

LIMIT 20;


-- ============================================================
-- 18. CUSTOMER VALUE CATEGORIES
-- ============================================================

SELECT
    customer_id,
    total_orders,
    net_spending,

    CASE
        WHEN net_spending >= 5000
            THEN 'High Value'

        WHEN net_spending >= 2000
            THEN 'Medium Value'

        ELSE 'Low Value'
    END AS value_category

FROM customer_summary

ORDER BY net_spending DESC;


-- ============================================================
-- 19. FINAL KPI QUERY
-- ============================================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,

    SUM(units) AS total_units_sold,

    ROUND(
        SUM(gross_payment),
        2
    ) AS gross_payment,

    ROUND(
        SUM(refund_amount),
        2
    ) AS total_refunds,

    ROUND(
        SUM(net_revenue),
        2
    ) AS net_revenue,

    ROUND(
        SUM(net_revenue) /
        COUNT(DISTINCT order_id),
        2
    ) AS average_order_value,

    ROUND(
        SUM(refund_amount) * 100.0 /
        NULLIF(SUM(gross_payment), 0),
        2
    ) AS refund_rate

FROM clean_orders;
