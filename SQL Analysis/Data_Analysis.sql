USE ecommerce_db;

SELECT * FROM products;

-- How can we accurately measure the financial and operational impact of Return-to-Origin (RTO) 
-- across different payment methods, geographic regions, and customer segments? Furthermore, 

-- how can we leverage historical buyer behavior to construct a risk-scoring model that reduces 
-- non-deliveries without sacrificing legitimate order volume?

-- 1. What is the overall RTO Rate?
-- By Order Volume = 12%, Total RTO orders = 1893, Total Orders = 16500
SELECT 
    COUNT(DISTINCT CASE WHEN rto_status = 'RTO' THEN order_id END) AS total_rto_orders,
    COUNT(DISTINCT order_id) AS total_orders,
    CEILING(COUNT(DISTINCT CASE WHEN rto_status = 'RTO' THEN order_id END) * 100.0 / COUNT(DISTINCT order_id)) 
    AS overall_rto_rate
FROM order_status_timeline;

-- By Financial Value 
-- Monetary value by RTO orders = Rs. 19,83,171
-- Total Gross Merchandise Value = Rs. 1,55,43,244 
-- Overall RTO rate by Order Value = 13%

WITH distinct_orders AS(
SELECT 
    order_id,
    SUM(quantity * unit_price) AS order_value
FROM (SELECT DISTINCT * FROM orders) o
GROUP BY order_id),                 -- Created one CTE to extract Total Orders & GMV

rto_orders AS(
SELECT 
    DISTINCT order_id
    FROM order_status_timeline
    WHERE rto_status = 'RTO'        -- Created a second CTE to extract RTO orders
)
SELECT 
    CEILING(SUM(CASE WHEN r.order_id IS NOT NULL THEN o.order_value ELSE 0 END)) AS total_rto_value,
    -- Sums the total GMV value of orders that appear in the RTO list (returning 0 for non-RTO orders)
    CEILING(SUM(o.order_value)) AS total_gmv,
    CEILING(
        SUM(CASE WHEN r.order_id IS NOT NULL THEN o.order_value ELSE 0 END) * 100.0 / 
        NULLIF(SUM(o.order_value), 0)) AS overall_rto_rate_by_value
FROM distinct_orders o
LEFT JOIN rto_orders r ON o.order_id = r.order_id;

-- 2. RTO rate in COD vs Prepaid orders
-- COD RTO Rate = 19%, Total RTO orders = 1893, Total COD orders = 8786
-- Total Orders those have RTO but has COD = 1654/8786
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.payment_mode = 'Cash On Delivery' THEN o.order_id END) AS total_cod_orders,
    COUNT(DISTINCT CASE WHEN ost.rto_status = 'RTO' THEN ost.order_id END) AS total_rto_orders,
    COUNT(DISTINCT CASE 
                        WHEN o.payment_mode = 'Cash On Delivery' AND ost.rto_status = 'RTO' 
                        THEN o.order_id END) AS cod_rto_orders,
    CAST(CEILING(100.0 * 
           COUNT(DISTINCT CASE WHEN o.payment_mode = 'Cash On Delivery' AND ost.rto_status = 'RTO' 
           THEN o.order_id END) /COUNT(DISTINCT CASE WHEN o.payment_mode = 'Cash On Delivery' THEN o.order_id END)) AS INT)AS cod_rto_rate
FROM orders o
LEFT JOIN order_status_timeline ost 
    ON o.order_id = ost.order_id;

-- Prepaid Order RTO Rate
-- Prepaid RTO Rate = 4%, Total RTO orders = 1893, Total Prepaid orders = 4892
-- Total Orders those have RTO but has Prepaid = 152/4892
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.payment_mode = 'Prepaid' THEN o.order_id END) AS total_prepaid_orders,
    COUNT(DISTINCT CASE WHEN ost.rto_status = 'RTO' THEN ost.order_id END) AS total_rto_orders,
    COUNT(DISTINCT CASE 
                        WHEN o.payment_mode = 'Prepaid' AND ost.rto_status = 'RTO' 
                        THEN o.order_id END) AS prepaid_rto_orders,
    CAST(CEILING(100.0 * 
           COUNT(DISTINCT CASE WHEN o.payment_mode = 'Prepaid' AND ost.rto_status = 'RTO' 
           THEN o.order_id END) /COUNT(DISTINCT CASE WHEN o.payment_mode = 'Prepaid' THEN o.order_id END)) AS INT)AS prepaid_rto_rate
FROM orders o
LEFT JOIN order_status_timeline ost 
    ON o.order_id = ost.order_id;

-- Location specific RTO rate (State/City)
-- Top 10 RTO states - Madhya Pradesh West Bengal Bihar Punjab Karnataka Gujarat Rajasthan Bihar Jharkhand Jharkhand
-- Top 10 RTO cities - Gwalior Asansol Gaya Amritsar Hubli Rajkot Jodhpur Muzaffarpur Jamshedpur Ranchi
SELECT TOP 10
    o.delivery_state,
    o.delivery_city,
    COUNT(DISTINCT CASE WHEN rto_status = 'RTO' THEN o.order_id END) AS total_rto_orders,
    CEILING(COUNT(DISTINCT CASE WHEN ost.rto_status = 'RTO' THEN o.order_id END) * 100.0 / COUNT(DISTINCT o.order_id)) 
    AS overall_rto_rate
FROM orders o
LEFT JOIN order_status_timeline ost 
ON o.order_id = ost.order_id
GROUP BY 
    o.delivery_state,
    o.delivery_city
ORDER BY overall_rto_rate DESC;

-- Delivery Delay / Turnaround Time (TAT) 
-- AVG Tat = 5 days, MAX Tat = 10 days, MIN Tat = 2 days
WITH FirstAttempt AS (
    SELECT
        order_id,
        MIN(attempt_date_time) AS first_attempt_date
    FROM delivery_attempts
    GROUP BY order_id),
TAT AS (
    SELECT
        o.order_id,
        DATEDIFF(DAY, o.order_datetime, f.first_attempt_date) AS tat_days
    FROM orders o
    JOIN FirstAttempt f
    ON o.order_id = f.order_id)
SELECT
    CEILING(AVG(tat_days * 1.0)) AS avg_tat_days,
    MIN(tat_days) AS min_tat_days,
    MAX(tat_days) AS max_tat_days
FROM TAT;

-- 3. Product & Seller Metrics
-- RTO Rate by Product Category
-- Jewellery & Cosmetics = 16%
-- Women Ethnic Wear = 16%
-- Footwear = 15%
-- Kids Wear = 13%
-- Men Fashion = 12%

SELECT
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN r.order_id IS NOT NULL THEN o.order_id END) AS total_rto_orders,
    CEILING(
        (COUNT(DISTINCT CASE WHEN r.order_id IS NOT NULL THEN o.order_id END) * 100.0) 
        / COUNT(DISTINCT o.order_id)) AS rto_rate_percentage
FROM orders o
JOIN products p 
    ON o.product_id = p.product_id
LEFT JOIN (
    -- Subquery prevents row duplication from timeline logs
    SELECT DISTINCT order_id 
    FROM order_status_timeline 
    WHERE rto_status = 'RTO'
) r ON o.order_id = r.order_id
GROUP BY p.category
ORDER BY rto_rate_percentage DESC;

-- Average Order Value (AOV)
SELECT
    COUNT(DISTINCT order_id) AS Total_Orders,
    CEILING(SUM(quantity * unit_price)) AS Total_GMV,
    ROUND(SUM(quantity * unit_price) / COUNT(DISTINCT order_id), 2) AS AOV
FROM (SELECT DISTINCT order_id, quantity, unit_price FROM orders) t;

-- RTO Rate by Value Bucket
-- over Rs.5000 has highest return RTO rate of 23%, it goes quite down for cheap products 
-- Over Rs.5,000 = 23%
-- Under Rs.500 = 8%
-- Rs.2,501 - Rs.5,000 = 6%
-- Rs.500 - Rs.1,000 = 2%
-- Rs.1,001 - Rs.2,500 = 2%

WITH order_totals AS (
    SELECT 
        o.order_id,
        SUM(o.quantity * o.unit_price) AS total_order_value,
        MAX(CASE WHEN ost.rto_status = 'RTO' THEN 1 ELSE 0 END) AS is_rto
    FROM orders o
    LEFT JOIN order_status_timeline ost ON o.order_id = ost.order_id
    GROUP BY o.order_id
)
SELECT
    CASE 
        WHEN total_order_value < 500 THEN 'Under Rs.500'
        WHEN total_order_value <= 1000 THEN 'Rs.500 - Rs.1,000'
        WHEN total_order_value <= 2500 THEN 'Rs.1,001 - Rs.2,500'
        WHEN total_order_value <= 5000 THEN 'Rs.2,501 - Rs.5,000'
        ELSE 'Over Rs.5,000'
    END AS value_bucket,
    COUNT(order_id) AS total_orders,
    SUM(is_rto) AS total_rto_orders,
    CEILING(100.0 * SUM(is_rto) / COUNT(order_id)) AS rto_rate_percentage
FROM order_totals
GROUP BY 
    CASE 
        WHEN total_order_value < 500 THEN 'Under Rs.500'
        WHEN total_order_value <= 1000 THEN 'Rs.500 - Rs.1,000'
        WHEN total_order_value <= 2500 THEN 'Rs.1,001 - Rs.2,500'
        WHEN total_order_value <= 5000 THEN 'Rs.2,501 - Rs.5,000'
        ELSE 'Over Rs.5,000'
    END
ORDER BY rto_rate_percentage DESC;

-- 4. Customer Behavior & Risk Metrics
-- Individual Customer RTO Rate
-- There are 1582 total customers who has RTO & 117 has returned all the orders those have ordered.
-- combining with these 546 customers has 40% RTO rate
WITH individual_RTO_rate AS
(SELECT
    o.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    COUNT(ost.order_id) AS total_rto_orders,
    ROUND(100.0 * COUNT(ost.order_id) / COUNT(o.order_id), 2) AS rto_rate_percentage
FROM (
    -- Subquery 1: Removes duplicate order rows
    SELECT DISTINCT order_id, customer_id
    FROM orders) o
JOIN customers c 
ON o.customer_id = c.customer_id
LEFT JOIN (
    -- Subquery 2: Isolates unique RTO order IDs
    SELECT DISTINCT order_id
    FROM order_status_timeline
    WHERE rto_status = 'RTO') ost ON o.order_id = ost.order_id
GROUP BY o.customer_id, c.customer_name)
SELECT 
    *
FROM individual_RTO_rate
WHERE rto_rate_percentage <> 0
ORDER BY rto_rate_percentage DESC;

-- Customer Risk Tiering
-- High risk = 546 customers
-- Medium Risk = 970 customers
-- Low Risk = 3609 customers
WITH individual_RTO_rate AS
(SELECT
    o.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    COUNT(ost.order_id) AS total_rto_orders,
    ROUND(100.0 * COUNT(ost.order_id) / COUNT(o.order_id), 2) AS rto_rate_percentage
FROM (
    -- Subquery 1: Removes duplicate order rows
    SELECT DISTINCT order_id, customer_id
    FROM orders) o
JOIN customers c 
ON o.customer_id = c.customer_id
LEFT JOIN (
    -- Subquery 2: Isolates unique RTO order IDs
    SELECT DISTINCT order_id
    FROM order_status_timeline
    WHERE rto_status = 'RTO') ost ON o.order_id = ost.order_id
GROUP BY o.customer_id, c.customer_name) 
SELECT 
    customer_id,
    customer_name,
    rto_rate_percentage,
    CASE 
        WHEN rto_rate_percentage < 15 THEN 'Low Risk'
        WHEN rto_rate_percentage < 40 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS Customer_Risk_Tiering
FROM individual_RTO_rate
ORDER BY rto_rate_percentage DESC;