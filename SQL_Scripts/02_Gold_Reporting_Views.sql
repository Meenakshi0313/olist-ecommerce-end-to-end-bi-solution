/*
===============================================================================
DDL Script: Create Gold Views 
===============================================================================
Script Purpose:
    - Creates the final Star Schema (Fact and Dimension tables).
    - Fixes Geolocation "Fan-out" (averaging Lat/Long per Zip Code).
    - Adds Business Logic Flags (Late Delivery, Approval Delays).
===============================================================================
*/

-- =============================================================================
-- Create Fact Table: v_FactOrderItems
-- =============================================================================

IF OBJECT_ID('v_FactOrderItems', 'V') IS NOT NULL
    DROP VIEW v_FactOrderItems;
GO

CREATE VIEW v_FactOrderItems AS
WITH payment_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value
    FROM silver.olist_order_payments_dataset
    GROUP BY order_id
),
review_agg AS (
    SELECT
        order_id,
        AVG(CAST(review_score AS FLOAT)) AS review_score
    FROM silver.olist_order_reviews_dataset
    GROUP BY order_id
)

SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,
    CONVERT(INT, FORMAT(o.order_purchase_timestamp, 'yyyyMMdd')) AS purchase_date_key,
    o.order_status,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date,

    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_item_value,
    pa.payment_value,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_approved_at) AS approval_days,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_days,
    DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delivery_vs_estimated_days,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
        WHEN o.order_delivered_customer_date IS NULL THEN 0 -- Orders still in progress
        ELSE 0 
    END AS is_late_delivery,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        WHEN o.order_delivered_customer_date IS NULL THEN 'In Transit/Pending'
        ELSE 'On-Time'
    END AS delivery_performance_status,
    ra.review_score,
    o.carrier_before_approval_flag,
    o.delivered_before_carrier_flag

FROM silver.olist_order_items_dataset oi
JOIN silver.olist_orders_dataset o ON oi.order_id = o.order_id
LEFT JOIN payment_agg pa ON oi.order_id = pa.order_id
LEFT JOIN review_agg ra ON oi.order_id = ra.order_id;
GO


-- =============================================================================
-- Create Dimension: v_DimCustomer 
-- =============================================================================

IF OBJECT_ID('v_DimCustomer ', 'V') IS NOT NULL
    DROP VIEW v_DimCustomer ;
GO

CREATE VIEW v_DimCustomer  AS
WITH geo_avg AS (
    SELECT 
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS customer_lat,
        AVG(geolocation_lng) AS customer_lng
    FROM silver.olist_geolocation_dataset
    GROUP BY geolocation_zip_code_prefix
)
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
     CASE c.customer_state
        WHEN 'AC' THEN 'Acre' WHEN 'AL' THEN 'Alagoas' WHEN 'AP' THEN 'Amapá'
        WHEN 'AM' THEN 'Amazonas' WHEN 'BA' THEN 'Bahia' WHEN 'CE' THEN 'Ceará'
        WHEN 'DF' THEN 'Distrito Federal' WHEN 'ES' THEN 'Espírito Santo'
        WHEN 'GO' THEN 'Goiás' WHEN 'MA' THEN 'Maranhão' WHEN 'MT' THEN 'Mato Grosso'
        WHEN 'MS' THEN 'Mato Grosso do Sul' WHEN 'MG' THEN 'Minas Gerais'
        WHEN 'PA' THEN 'Pará' WHEN 'PB' THEN 'Paraíba' WHEN 'PR' THEN 'Paraná'
        WHEN 'PE' THEN 'Pernambuco' WHEN 'PI' THEN 'Piauí' WHEN 'RJ' THEN 'Rio de Janeiro'
        WHEN 'RN' THEN 'Rio Grande do Norte' WHEN 'RS' THEN 'Rio Grande do Sul'
        WHEN 'RO' THEN 'Rondônia' WHEN 'RR' THEN 'Roraima' WHEN 'SC' THEN 'Santa Catarina'
        WHEN 'SP' THEN 'São Paulo' WHEN 'SE' THEN 'Sergipe' WHEN 'TO' THEN 'Tocantins'
        ELSE c.customer_state 
    END AS customer_state_full,
    c.customer_zip_code_prefix,
    ga.customer_lat,
    ga.customer_lng
FROM silver.olist_customers_dataset c
LEFT JOIN geo_avg ga ON c.customer_zip_code_prefix = ga.geolocation_zip_code_prefix;
GO


-- =============================================================================
-- Create Dimension: v_DimProduct
-- =============================================================================

IF OBJECT_ID('v_DimProduct', 'V') IS NOT NULL
    DROP VIEW v_DimProduct;
GO

CREATE VIEW v_DimProduct AS
SELECT
    p.product_id,
    p.product_category_name,
    UPPER(LEFT(REPLACE(t.product_category_name_english, '_', ' '), 1)) + 
    LOWER(SUBSTRING(REPLACE(t.product_category_name_english, '_', ' '), 2, LEN(product_category_name_english))) 
    AS product_category_name_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM silver.olist_products_dataset p
LEFT JOIN silver.product_category_name_translation t 
    ON p.product_category_name = t.product_category_name;
GO


-- =============================================================================
-- Create Dimension: v_DimSeller 
-- =============================================================================

IF OBJECT_ID('v_DimSeller ', 'V') IS NOT NULL
    DROP VIEW v_DimSeller ;
GO

CREATE VIEW v_DimSeller  AS
WITH geo_avg AS (
    SELECT 
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS seller_lat,
        AVG(geolocation_lng) AS seller_lng
    FROM silver.olist_geolocation_dataset
    GROUP BY geolocation_zip_code_prefix
)
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
     CASE s.seller_state
        WHEN 'AC' THEN 'Acre' WHEN 'AM' THEN 'Amazonas' WHEN 'BA' THEN 'Bahia'
        WHEN 'CE' THEN 'Ceará' WHEN 'DF' THEN 'Distrito Federal' WHEN 'ES' THEN 'Espírito Santo'
        WHEN 'GO' THEN 'Goiás' WHEN 'MA' THEN 'Maranhão' WHEN 'MT' THEN 'Mato Grosso'
        WHEN 'MS' THEN 'Mato Grosso do Sul' WHEN 'MG' THEN 'Minas Gerais'
        WHEN 'PA' THEN 'Pará' WHEN 'PB' THEN 'Paraíba' WHEN 'PR' THEN 'Paraná'
        WHEN 'PE' THEN 'Pernambuco' WHEN 'PI' THEN 'Piauí' WHEN 'RJ' THEN 'Rio de Janeiro'
        WHEN 'RN' THEN 'Rio Grande do Norte' WHEN 'RS' THEN 'Rio Grande do Sul'
        WHEN 'RO' THEN 'Rondônia' WHEN 'SC' THEN 'Santa Catarina'
        WHEN 'SP' THEN 'São Paulo' WHEN 'SE' THEN 'Sergipe'
        ELSE seller_state 
    END AS seller_state_full,
    s.seller_zip_code_prefix,
    ga.seller_lat,
    ga.seller_lng
FROM silver.olist_sellers_dataset s
LEFT JOIN geo_avg ga ON s.seller_zip_code_prefix = ga.geolocation_zip_code_prefix;
GO


-- =============================================================================
-- Create Dimension: v_DimDate
-- =============================================================================

IF OBJECT_ID('v_DimDate', 'V') IS NOT NULL
    DROP VIEW v_DimDate;
GO

CREATE VIEW v_DimDate AS
SELECT DISTINCT
    CONVERT(INT, FORMAT(order_purchase_timestamp, 'yyyyMMdd')) AS date_key,
    CAST(order_purchase_timestamp AS DATE) AS full_date,
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp) AS month,
    DATENAME(MONTH, order_purchase_timestamp) AS month_name,
    DATEPART(QUARTER, order_purchase_timestamp) AS quarter,
    DATENAME(WEEKDAY, order_purchase_timestamp) AS day_of_week
FROM silver.olist_orders_dataset;
GO
