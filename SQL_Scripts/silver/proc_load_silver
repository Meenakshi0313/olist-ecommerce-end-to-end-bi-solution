/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

	
		-- Loading silver.olist_customers_dataset
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_customers_dataset;';
		TRUNCATE TABLE silver.olist_customers_dataset;
		PRINT '>> Inserting Data Into: silver.olist_customers_dataset';
        INSERT INTO silver.olist_customers_dataset (
				customer_id,
				customer_unique_id,
				customer_zip_code_prefix,
				customer_city,
				customer_state
		)
		SELECT
			customer_id                          AS customer_id,
			customer_unique_id                   AS customer_unique_id,
			customer_zip_code_prefix,
			UPPER(LTRIM(RTRIM(customer_city)))   AS customer_city,
			UPPER(LTRIM(RTRIM(customer_state)))  AS customer_state
        FROM bronze.olist_customers_dataset;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading silver.olist_geolocation_dataset
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_geolocation_dataset';
		TRUNCATE TABLE silver.olist_geolocation_dataset;
		PRINT '>> Inserting Data Into: silver.olist_geolocation_dataset';
		INSERT INTO silver.olist_geolocation_dataset (
					geolocation_zip_code_prefix,
					geolocation_lat,      
					geolocation_lng, 
					geolocation_city,
					geolocation_state 
		)
		SELECT
		    geolocation_zip_code_prefix,
			AVG(geolocation_lat) AS geolocation_lat,
			AVG(geolocation_lng) AS geolocation_lng,
			MIN(LTRIM(TRIM(geolocation_city))) AS geolocation_city,
			MIN(geolocation_state) AS geolocation_state
		FROM bronze.olist_geolocation_dataset
		GROUP BY geolocation_zip_code_prefix;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading silver.olist_order_items_dataset
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_order_items_dataset';
		TRUNCATE TABLE silver.olist_order_items_dataset;
		PRINT '>> Inserting Data Into: silver.olist_order_items_dataset';
		INSERT INTO silver.olist_order_items_dataset (
					order_id,
					order_item_id,
					product_id,
					seller_id,
					shipping_limit_date,
					price,
					freight_value	
		)
		SELECT 
		order_id,
		CAST(order_item_id AS TINYINT),
		product_id,
		seller_id,
		TRY_CONVERT(DATETIME2, shipping_limit_date, 105) AS shipping_limit_date,
		price,
		freight_value
		FROM bronze.olist_order_items_dataset;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- Loading silver.olist_order_payments_dataset
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_order_payments_dataset';
		TRUNCATE TABLE silver.olist_order_payments_dataset;
		PRINT '>> Inserting Data Into: silver.olist_order_payments_dataset';
		INSERT INTO silver.olist_order_payments_dataset (
					order_id,
					payment_sequential,
					payment_type,
					payment_installments,
					payment_value
		)
		SELECT
			order_id,
			CAST(payment_sequential AS TINYINT) AS payment_sequential,
			LOWER(LTRIM(TRIM(payment_type))) AS payment_type,
			CAST(payment_installments AS TINYINT) AS payment_installments,
			payment_value
		FROM bronze.olist_order_payments_dataset
		WHERE payment_value > 0;
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		

        -- Loading silver.olist_order_reviews_dataset
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_order_reviews_dataset';
		TRUNCATE TABLE silver.olist_order_reviews_dataset;
		PRINT '>> Inserting Data Into: silver.olist_order_reviews_dataset';
		INSERT INTO silver.olist_order_reviews_dataset (
				review_id,
				order_id,
				review_score,
				review_comment_title,
				review_comment_message,
				review_creation_date,
				review_answer_timestamp 
		)
		SELECT 
				LTRIM(RTRIM(review_id)) AS review_id,
				LTRIM(RTRIM(order_id)) AS order_id,
				CAST(review_score AS TINYINT) AS review_score,
				LEFT(LTRIM(RTRIM(review_comment_title)), 150) AS review_comment_title,
				LEFT(LTRIM(RTRIM(review_comment_message)), 500) AS review_comment_message,
				TRY_CONVERT(DATETIME2,review_creation_date, 105)  AS review_creation_date,
				TRY_CONVERT(DATETIME2,review_answer_timestamp, 105)  AS review_answer_timestamp
		FROM (
		SELECT *,
		ROW_NUMBER() OVER(PARTITION BY LTRIM(RTRIM(review_id)) ORDER BY TRY_CONVERT(DATETIME2, review_creation_date, 105) DESC) AS rn
		FROM bronze.olist_order_reviews_dataset
		) AS ranked_reviews
		WHERE rn = 1
		AND LTRIM(RTRIM(order_id)) IN (SELECT LTRIM(RTRIM(order_id)) FROM silver.olist_orders_dataset);
		
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		-- Loading silver.olist_orders_dataset
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_orders_dataset';
		TRUNCATE TABLE silver.olist_orders_dataset;
		PRINT '>> Inserting Data Into: silver.olist_orders_dataset';
		INSERT INTO silver.olist_orders_dataset (
				order_id ,
				customer_id ,
				order_status ,
				order_purchase_timestamp,
				order_approved_at,
				order_delivered_carrier_date,
				order_delivered_customer_date,
				order_estimated_delivery_date ,
				carrier_before_approval_flag,
				delivered_before_carrier_flag
					)
		SELECT
			order_id,
			customer_id,
			LOWER(LTRIM(TRIM(order_status))) AS order_status,
			TRY_CONVERT(DATETIME2, order_purchase_timestamp, 105) AS order_purchase_timestamp,
			TRY_CONVERT(DATETIME2, order_approved_at, 105) AS order_approved_at,
			TRY_CONVERT(DATETIME2, order_delivered_carrier_date, 105) AS order_delivered_carrier_date,
			TRY_CONVERT(DATETIME2, order_delivered_customer_date, 105) AS order_delivered_customer_date,
            TRY_CONVERT(DATETIME2, order_estimated_delivery_date, 105) AS order_estimated_delivery_date,
			CASE
			WHEN TRY_CONVERT(DATETIME2, order_delivered_carrier_date, 105) < TRY_CONVERT(DATETIME2, order_approved_at, 105) THEN 1
			ELSE 0 
			END AS carrier_before_approval_flag,
			CASE
			WHEN TRY_CONVERT(DATETIME2, order_delivered_customer_date, 105) < TRY_CONVERT(DATETIME2, order_delivered_carrier_date, 105) THEN 1
			ELSE 0
			END AS delivered_before_carrier_flag
		FROM bronze.olist_orders_dataset
		
;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading silver.olist_products_dataset
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_products_dataset';
		TRUNCATE TABLE silver.olist_products_dataset;
		PRINT '>> Inserting Data Into: silver.olist_products_dataset';
		INSERT INTO silver.olist_products_dataset (
			    product_id,                 
				product_category_name,      
				product_name_length,       
				product_description_length, 
				product_photos_qty,         
				product_weight_g,         
				product_length_cm ,         
				product_height_cm ,        
				product_width_cm  
		)
		SELECT
				LTRIM(RTRIM(product_id))  AS product_id,                 
				LTRIM(RTRIM(product_category_name)) AS product_category_name,      
				product_name_lenght AS product_name_length,  --typo correct     
				product_description_lenght AS product_description_length , --typo correct
				product_photos_qty ,         
				CASE WHEN product_weight_g IS NOT NULL THEN CAST(product_weight_g AS INT) ELSE NULL END AS product_weight_g,         
				CASE WHEN product_length_cm IS NOT NULL THEN CAST(product_length_cm AS INT) ELSE NULL END AS product_length_cm ,         
				CASE WHEN product_height_cm IS NOT NULL THEN CAST(product_height_cm AS INT) ELSE NULL END AS product_height_cm ,        
				CASE WHEN product_width_cm IS NOT NULL THEN CAST(product_width_cm AS INT) ELSE NULL END  AS product_width_cm 
		FROM bronze.olist_products_dataset
		WHERE product_id IS NOT NULL
		AND product_category_name IS NOT NULL; --skip 610 rows
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

				-- Loading silver.olist_sellers_dataset
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.olist_sellers_dataset';
		TRUNCATE TABLE silver.olist_sellers_dataset;
		PRINT '>> Inserting Data Into: silver.olist_sellers_dataset'
		INSERT INTO silver.olist_sellers_dataset (
				seller_id,
				seller_zip_code_prefix,
				seller_city,
				seller_state 
		)
		SELECT
				LTRIM(TRIM(seller_id)) AS seller_id,
				CAST(seller_zip_code_prefix AS INT) AS seller_zip_code_prefix,
				LTRIM(RTRIM(seller_city)) AS seller_city,
				LTRIM(RTRIM(seller_state)) AS seller_state
		FROM bronze.olist_sellers_dataset;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

				-- Loading silver.product_category_name_translation
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.product_category_name_translation';
		TRUNCATE TABLE silver.product_category_name_translation;
		PRINT '>> Inserting Data Into: silver.product_category_name_translation';
		INSERT INTO silver.product_category_name_translation (
				 product_category_name,
				 product_category_name_english 
		)
		SELECT DISTINCT
		 LTRIM(TRIM(product_category_name)) AS product_category_name,
		 LTRIM(RTRIM(product_category_name_english)) AS product_category_name_english 
		FROM bronze.product_category_name_translation;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State: ' + CAST (ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
