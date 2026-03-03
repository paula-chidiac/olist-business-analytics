/*
===============================================================================
Script DDL: Criando as tabelas da camada bronze
===============================================================================

Objetivo do script: 
  Criar as tabelas na camada bronze, apagando tabelas já existentes. 

===============================================================================
*/

DROP TABLE IF EXISTS bronze.geolocation;
CREATE TABLE bronze.geolocation (
	geolocation_zip_code_prefix TEXT, --Preserva zeros à esquerda
	geolocation_lat 			NUMERIC (9,6),
	geolocation_lng 			NUMERIC (9,6),
	geolocation_city 			TEXT,
	geolocation_state 			TEXT
);

DROP TABLE IF EXISTS bronze.customers;
CREATE TABLE bronze.customers (
	customer_id 				TEXT,
	customer_unique_id 			TEXT,
	customer_zip_code_prefix 	TEXT,
	customer_city 				TEXT,
	customer_state 				TEXT

);

DROP TABLE IF EXISTS bronze.sellers;
CREATE TABLE bronze.sellers (
	seller_id 					TEXT,
	seller_zip_code_prefix 		TEXT,
	seller_city 				TEXT,
	seller_state 				TEXT

);

DROP TABLE IF EXISTS bronze.products;
CREATE TABLE bronze.products (
	product_id 					TEXT,
	product_category_name 		TEXT,
	product_name_lenght 		INT,
	product_description_lenght 	INT,
	product_photos_qty 			INT,
	product_weight_g 			INT,
	product_length_cm 			INT,
	product_height_cm 			INT,
	product_width_cm 			INT
);

DROP TABLE IF EXISTS bronze.orders;
CREATE TABLE bronze.orders(
	order_id 						TEXT,
	customer_id 					TEXT,
	order_status 					TEXT,
	order_purchase_timestamp 		TIMESTAMP,
	order_approved_at 				TIMESTAMP,
	order_delivered_carrier_date 	TIMESTAMP,
	order_delivered_customer_date 	TIMESTAMP,
	order_estimated_delivery_date 	DATE
);

DROP TABLE IF EXISTS bronze.order_payments;
CREATE TABLE bronze.order_payments (
	order_id 			TEXT,
	payment_sequential 	INT,
	payment_type		TEXT,
	payment_installment INT,
	payment_value 		NUMERIC(10,2)
);

DROP TABLE IF EXISTS bronze.order_reviews;
CREATE TABLE bronze.order_reviews (
	review_id 				TEXT,
	order_id 				TEXT,
	review_score 			INT,
	review_comment_title 	TEXT,
	review_comment_message 	TEXT,
	review_creation_date 	DATE,
	review_answer_timestamp TIMESTAMP
);

DROP TABLE IF EXISTS bronze.order_items;
CREATE TABLE bronze.order_items (
	order_id 			TEXT,
	order_item_id 		INT,
	product_id 			TEXT,
	seller_id 			TEXT,
	shipping_limit_date TIMESTAMP,
	price 				NUMERIC(10,2),
	freight_value 		NUMERIC(10,2)
);
