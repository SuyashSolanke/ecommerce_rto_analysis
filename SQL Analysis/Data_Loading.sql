USE ecommerce_db;

CREATE TABLE customers
(
	customer_id VARCHAR(15) PRIMARY KEY,
    customer_name VARCHAR(20),
    phone_number VARCHAR(15),
    mail VARCHAR(40),
    registered_pincode VARCHAR(6),
    registered_city	VARCHAR(25),
    registered_state VARCHAR(15),
    signup_date	DATE,
    acquisition_channel VARCHAR(20)
);

CREATE TABLE delivery_attempts
(
	attempt_id VARCHAR(15) PRIMARY KEY,
	order_id VARCHAR(15),
	attempt_number INT,
	attempt_date_time DATETIME,
	attempt_status VARCHAR(35),
	remarks	VARCHAR(60),
    otp_shared CHAR(5)
);

CREATE TABLE order_status_timeline
(
	event_id VARCHAR(15) PRIMARY KEY,
    order_id VARCHAR(15),
    order_status VARCHAR(30),
    event_timestamp DATETIME,
    updated_by VARCHAR(20)
);

CREATE TABLE orders
(
	order_id VARCHAR(15),
    customer_id VARCHAR(15),
    product_id VARCHAR(15),
    order_datetime DATETIME,
    quantity INT,
    unit_price DECIMAL(10, 2),
    payment_mode VARCHAR(20),
    delivery_pincode VARCHAR(15),
    delivery_city VARCHAR(20),
    delivery_state VARCHAR(15),
    order_channel VARCHAR(30),
    coupon_code VARCHAR(10),
    promised_delivery_days INT
);

CREATE TABLE products
(
	product_id VARCHAR(15) PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(25),
    subcategory VARCHAR(25),
    brand VARCHAR(25),
    mrp INT,
    weight_grams INT,
    is_fragile VARCHAR(5),
    seller_name VARCHAR(30),
    seller_warehouse_city VARCHAR(20),
    seller_warehouse_state VARCHAR(15),
    seller_warehouse_pincode VARCHAR(6),
    seller_rating DECIMAL(10,2),
    listing_date DATE
);

SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv' 
INTO TABLE products 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
-- 1. Map listing_date to a temporary variable @v_date at the end of the list
(product_id, product_name, category, subcategory, brand, mrp, @v_weight, is_fragile, seller_name, seller_warehouse_city, seller_warehouse_state, seller_warehouse_pincode, @v_rating, @v_date) 
SET 
  weight_grams = IF(TRIM(@v_weight) = '', NULL, @v_weight), 
  seller_rating = IF(TRIM(@v_rating) = '', NULL, @v_rating),
  -- 2. Convert 'DD-MM-YYYY' into a MySQL-compatible date format
  listing_date = IF(TRIM(@v_date) = '', NULL, STR_TO_DATE(@v_date, '%d-%m-%Y'));





SHOW VARIABLES LIKE "secure_file_priv";


