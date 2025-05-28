# Monday Coffee Expansion SQL Project

![Company Logo](https://github.com/najirh/Monday-Coffee-Expansion-Project-P8/blob/main/1.png)

## Objective
The goal of this project is to analyze the sales data of Monday Coffee, a company that has been selling its products online since January 2023, and to recommend the top three major cities in India for opening new coffee shop locations based on consumer demand and sales performance.

## Key Questions
1. **Coffee Consumers Count**  
   How many people in each city are estimated to consume coffee, given that 25% of the population does?
```sql
SELECT 
	city_id,
	city_name,
	population,
	ROUND((population * 0.25),0) AS estimated_coffee_drinkers
FROM city;
```
2. **Total Revenue from Coffee Sales**  
   What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
```sql
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;
```
3. **Sales Count for Each Product**  
   How many units of each coffee product have been sold?
```sql
SELECT 
	products.product_name,
	COUNT(sal.sale_id)
FROM products
LEFT JOIN sales AS sal
ON sal.product_id = products.product_id
GROUP BY 1
ORDER BY 2 DESC;
```
4. **Average Sales Amount per City**  
   What is the average sales amount per customer in each city?
```sql
SELECT 
	ci.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) AS avg_sales_per_cx
FROM sales AS s
JOIN customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;
```
5. **City Population and Coffee Consumers**  
   Provide a list of cities along with their populations and estimated coffee consumers.
```sql
WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales AS s
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;
```
6. **Top Selling Products by City**  
   What are the top 3 selling products in each city based on sales volume?
```sql
SELECT * 
FROM 
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales AS s
	JOIN products AS p
	ON s.product_id = p.product_id
	JOIN customers AS c
	ON c.customer_id = s.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
) AS t1
WHERE rank <= 3;
```
7. **Customer Segmentation by City**  
   How many unique customers are there in each city who have purchased coffee products?
```sql
SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
FROM city AS ci
LEFT JOIN customers AS c
ON c.city_id = ci.city_id
JOIN sales AS s
ON c.customer_id = s.customer_id
WHERE 
	s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14) 
GROUP BY 1;
```
8. **Average Sale vs Rent**  
   Find each city and their average sale per customer and avg rent per customer
```sql
WITH city_table
AS
	(SELECT 
		ci.city_name,
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) AS avg_sales_per_cx
	FROM sales AS s
	JOIN customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sales_per_cx,
	ROUND
		(cr.estimated_rent::numeric / ct.total_cX::numeric,0) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC;
```
9. **Monthly Sales Growth**  
   Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
```sql
WITH monthly_sales AS (
	SELECT 
		ci.city_name,
		EXTRACT(Month FROM sale_date) AS month,
		EXTRACT(YEAR FROM sale_date) AS year,
		SUM(s.total) AS total_sales
	FROM sales AS s
	JOIN customers AS c ON c.customer_id = s.customer_id
	JOIN city AS ci ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT 
			city_name,
			month,
			year,
			total_sales AS current_month_sales,
			LAG(total_sales, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sales
		FROM monthly_sales
)

SELECT 
	city_name,
	month,
	year,
	current_month_sales,
	last_month_sales,
	ROUND(
		(current_month_sales - last_month_sales)::numeric / last_month_sales::numeric * 100, 2) AS percentage_growth
FROM growth_ratio
WHERE
	last_month_sales IS NOT NULL;

```
10. **Market Potential Analysis**  
    Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated  coffee consumer
 ```sql
WITH city_table
AS
	(SELECT 
		ci.city_name,
		SUM(s.total) AS total_revenue,
		COUNT(DISTINCT s.customer_id) AS total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) AS avg_sales_per_cx
	FROM sales AS s
	JOIN customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		Round((population * 0.25)/1000000,2) AS estimated_coffee_consumer_in_million
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent AS total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_million,
	ct.avg_sales_per_cx,
	ROUND
		(cr.estimated_rent::numeric / ct.total_cX::numeric,0) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC; 
```
## Recommendations
After analyzing the data, the recommended top three cities for new store openings are:

**City 1: Pune**  
1.Average rent per customer is low.
2.Highest total revenue.
3.Average sales per customer is also high.

**City 2: Delhi**  
1.Highest estimated coffee consumers at 7.7 million.
2.Highest total number of customers, at 68.
3.Average rent per customer is 330 which is under 500.

**City 3: Jaipur**  
1.Highest number of customers, which is 69.
2.Average rent per customer at 156.
3.Average sales per customer is better at 11.6k.

---
