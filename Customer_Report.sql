/*
========================================================================================================
Purpose:
	-This report consolidates key customer metrics and behaviors.

Highlights:
	1. Gather essentials fields such as names,ages and transactions details.
	2. Segment customer into categories (VIP,Regular,New) and age groups.
	3. Aggregate Customer-level metrics:
		- total orders
		- total Sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	4. Calculates valuable KPIs:
		-recency (months since last order)
*/


CREATE VIEW gold.report_customer AS
WITH base_query AS(
--1). Base query: Retrieves core columns from tables 
SELECT 
S.order_number,
S.product_key,
S.order_date,
S.sales_amount,
S.quantity,
C.customer_key,
C.customer_number,
CONCAT(C.first_name,' ',C.last_name) AS Customer_Name,
DATEDIFF(YEAR,C.birthdate,GETDATE()) AS Age
FROM GOLD.fact_sales S
LEFT JOIN GOLD.dim_customers C
ON S.customer_key=C.customer_key
WHERE order_date IS NOT NULL
),
customer_aggregation AS
(
--2).Customer Aggregation: Summarizes key metrics at the Customer level
SELECT 
customer_key,
customer_number,
Customer_Name,
Age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_qty,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order,
DATEDIFF(MONTH,MIN(order_date),MAX(Order_date)) AS lifespan
FROM base_query
GROUP BY customer_key,Customer_Name,customer_number,Age
)
SELECT 
customer_key,
customer_number,
Customer_Name,
Age,
CASE WHEN Age < 20 THEN 'Under 20'
	 WHEN Age BETWEEN 20 AND 29 THEN '20-29'
	 WHEN Age BETWEEN 30 AND 39 THEN '30-39'
	 WHEN Age BETWEEN 40 AND 49 THEN '40-49'
	 ELSE '50 and Above'
END age_group,
CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP' 
	 WHEN lifespan >= 12 AND total_sales <=5000 THEN 'Regular'
	 ELSE 'New'
END customer_segment,
last_order,
DATEDIFF(MONTH,last_order,GETDATE()) AS recency,
total_orders,
total_sales,
total_qty,
total_products,
lifespan,
--compute average order
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_sales/total_orders
END avg_order_value,
--compute average monthly spend 
CASE WHEN lifespan = 0 THEN total_sales 
	 ELSE total_sales/lifespan 
END avg_monthly_spend
FROM customer_aggregation

--CALL VIEW (which made in above)
SELECT * FROM gold.report_customer
