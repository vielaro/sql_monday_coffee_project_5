-- Data Analysis for Monday Coffee

SELECT *FROM city;
SELECT *FROM products;
SELECT *FROM customers;
SELECT *FROM sales;

--Reports and Data Analysis

--Q1. How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	city_id,
	city_name,
	population,
	ROUND((population * 0.25),0) AS estimated_coffee_drinkers
FROM city;

--Q2. What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC

--3.How many units of each coffee product have been sold?
SELECT 
	products.product_name,
	COUNT(sal.sale_id)
FROM products
LEFT JOIN sales AS sal
ON sal.product_id = products.product_id
GROUP BY 1
ORDER BY 2 DESC


--4.What is the average sales amount per customer in each city?

SELECT 
	city.city_name,
	cus.customer_name,
	ROUND(AVG(sal.total)::numeric, 2) AS avg_sales
FROM city 
JOIN customers AS cus
ON cus.city_id = city.city_id
JOIN sales AS sal
ON sal.customer_id = cus.customer_id
GROUP BY 1, 2
ORDER BY 1


--5.Provide a list of cities along with their populations and estimated coffee consumers.