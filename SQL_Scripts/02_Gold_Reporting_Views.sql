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
        MAX(review_id) AS review_id,
        AVG(CAST(review_score AS FLOAT)) AS review_score
    FROM silver.olist_order_reviews_dataset
    GROUP BY order_id
)

SELECT
    oi.order_id AS [Order Id],
    oi.order_item_id AS [Order Item Id],
    o.customer_id AS [Customer Id],
    oi.product_id AS [Product Id],
    oi.seller_id AS [Seller Id],
    CONVERT(INT, FORMAT(o.order_purchase_timestamp, 'yyyyMMdd')) AS [Purchase Date Key],
    o.order_status AS [Order Status],
    o.order_estimated_delivery_date AS [Order Estimated Delivery Date],
    o.order_delivered_customer_date AS [Order Delivered Customer Date],
    oi.price AS Price,
    oi.freight_value AS [Freight Value],
    CASE 
        WHEN oi.price <= 50 THEN 'Low Value (<$50)'
        WHEN oi.price <= 200 THEN 'Mid Value ($50-$200)'
        ELSE 'High Value (>$200)'
    END AS [Price Segment],
    (oi.price + oi.freight_value) AS [Total Item Value],
    pa.payment_value AS [Payment Value],
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_approved_at) AS [Approval Days],
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS [Delivery Days],
    DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS [Delivery vs Estimated Days],
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
        WHEN o.order_delivered_customer_date IS NULL THEN 0 -- Orders still in progress
        ELSE 0 
    END AS [Is Late Delivery],
    CASE 
    WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
    THEN DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)
    ELSE 0 
   END AS [Days Delay],
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        WHEN o.order_delivered_customer_date IS NULL THEN 'In Transit/Pending'
        ELSE 'On-Time'
    END AS [Delivery Performance Status],
    ra.review_id AS [Review Id],    
    ra.review_score AS [Review Score],
    o.carrier_before_approval_flag AS [Carrier Before Approval Flag],
    o.delivered_before_carrier_flag AS [Delivered Before Carrier Flag]

FROM silver.olist_order_items_dataset oi
JOIN silver.olist_orders_dataset o ON oi.order_id = o.order_id
LEFT JOIN payment_agg pa ON oi.order_id = pa.order_id
LEFT JOIN review_agg ra ON oi.order_id = ra.order_id
WHERE o.order_purchase_timestamp >= '2017-01-01'
AND o.order_purchase_timestamp <= '2018-08-31';
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
    c.customer_id AS [Customer Id],
    c.customer_unique_id AS [Customer Unique id],
    c.customer_city AS [Customer City],
    c.customer_state AS [Customer State],
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
    END AS [Customer State Full],
    c.customer_zip_code_prefix AS [Customer Zip Code Prefix],
    ga.customer_lat AS [Customer Latitude],
    ga.customer_lng AS [Customer Longitude],
    COUNT(c.customer_id) OVER(PARTITION BY c.customer_unique_id) AS [Total Lifetime Orders],
    CASE 
        WHEN COUNT(c.customer_id) OVER(PARTITION BY c.customer_unique_id) > 1 THEN 'Returning'
        ELSE 'New'
    END AS [Customer Segment]
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
    p.product_id AS [Product Id],
    ISNULL(p.product_category_name, 'Unknown') AS [Product Category Name],
    ISNULL(
        UPPER(LEFT(REPLACE(t.product_category_name_english, '_', ' '), 1)) + 
        LOWER(SUBSTRING(REPLACE(t.product_category_name_english, '_', ' '), 2, LEN(t.product_category_name_english))),
        'Unknown'
    ) AS [Product Category Name English],
    p.product_weight_g AS [Product Weight (g)],
    p.product_length_cm AS [Product Length (cm)],
    p.product_height_cm AS [Product Height (cm)],
    p.product_width_cm AS [Product Width (cm)]
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
    s.seller_id AS [Seller Id],
    s.seller_city AS [Seller City],
    s.seller_state AS [Seller State],
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
    END AS [Seller State Full],
    s.seller_zip_code_prefix AS [Seller Zip Code Prefix],
    ga.seller_lat AS [Seller Latitude],
    ga.seller_lng AS [Seller Longitude]
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
WITH UniqueKeys AS (
    SELECT DISTINCT [Purchase Date Key]
    FROM [dbo].[v_FactOrderItems]
    WHERE [Purchase Date Key] IS NOT NULL
),
DateBase AS (
    SELECT 
        [Purchase Date Key] AS date_key,
        CAST(CAST([Purchase Date Key] AS CHAR(8)) AS DATE) AS full_date
    FROM UniqueKeys
)
SELECT 
    date_key AS [Date Key],
    full_date AS [Full Date],
    YEAR(full_date) AS [Year],
    MONTH(full_date) AS [Month],
    DATENAME(MONTH, full_date) AS [Month Name],
    LEFT(DATENAME(MONTH, full_date), 3) AS [Month Short],
    FORMAT([full_date], 'dd MMM') AS [Date Short], 
    (MONTH([full_date]) * 100) + DAY([full_date]) AS [Date Short Sort],
    DATEPART(QUARTER, full_date) AS [Quarter],
    DATENAME(WEEKDAY, full_date) AS [Day Of Week]
FROM DateBase;
GO
