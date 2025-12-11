-- #1 Describing
DESC customers;
DESc products;
DESC orders;
Desc orderdetails;

-- #2 Market Segmentation Analysis
Select location, count(*) as 
number_of_customers
From customers
group by location 
order by number_of_customers desc
limit 3;

#3 Engagement Depth analysis
SELECT 
    total_orders AS NumberOfOrders,
    COUNT(*) AS CustomerCount
FROM (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
   FROM orders
    GROUP BY customer_id
) AS t
GROUP BY total_orders
ORDER BY total_orders;

-- Segementing as Number of Orders (1,2-4,>4)
SELECT 
     CASE
        WHEN cnt = 1 THEN '1'
        WHEN cnt BETWEEN 2 AND 4 THEN '2-4'
        ELSE '>4'
    END AS NumberOfOrders,
    COUNT(*) AS CustomerCount
FROM (
    SELECT 
        customer_id,
        COUNT(*) AS cnt
   FROM orders
    GROUP BY customer_id
) AS t
GROUP BY NumberOfOrders
ORDER BY CASE NumberOfOrders
           WHEN '1' THEN 1
           WHEN '2-4' THEN 2
           WHEN '>4' THEN 3
         END;

#4 Purchase High Value Products
Select product_id as Product_Id,
avg(quantity) as AvgQuantity,
sum(quantity*price_per_unit) as TotalRevenue
from orderdetails
group by product_id
having avg(quantity)=2
order by AvgQuantity DESC,TotalRevenue Desc;

#5 Category-Wise Customer Reach 
	Select p.category, count(Distinct o.customer_id) as unique_customers
From products p
join orderdetails od on p.product_id=od.product_id
join orders o on od.order_id=o.order_id
group by category
order by unique_customers desc

#6 Sales Trend Analysis
WITH Sales AS (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS Month,
    SUM(total_amount) AS TotalSales
  FROM Orders
  GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
  Month,
  TotalSales,
  ROUND(
    (TotalSales - LAG(TotalSales) OVER (ORDER BY Month))
    / NULLIF(LAG(TotalSales) OVER (ORDER BY Month), 0) * 100
  , 2) AS PercentChange
FROM Sales
ORDER BY Month;

-- #7 Average Order Value Fluctuation
WITH Sales AS (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS Month,
    Round(avg(total_amount),2) as AvgOrderValue
  FROM Orders
  GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
  Month,
  AvgOrderValue,
  ROUND(
    (AvgOrderValue - LAG(AvgOrderValue) OVER (ORDER BY Month))
  , 2) AS ChangeInValue
FROM Sales
ORDER BY month;

-- #8 Inventory Refresh Rate
Select product_id, count(*) as SalesFrequency
From OrderDetails
Group by product_id
Order by SalesFrequency DESC
Limit 5;

#9 Low Engagement Prices
SELECT
  p.product_id      AS Product_id,
  p.name            AS Name,
  COUNT(DISTINCT c.customer_id) AS UniqueCustomerCount
FROM products AS p
JOIN orderdetails od ON p.product_id = od.product_id
JOIN orders o        ON od.order_id    = o.order_id
JOIN customers c     ON o.customer_id   = c.customer_id
GROUP BY p.product_id, p.name
HAVING COUNT(DISTINCT c.customer_id) < 0.4 * (SELECT COUNT(*) FROM customers);

#10 Customer Aquisition Trends
WITH FirstOrders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS FirstPurchaseDate
    FROM orders
    GROUP BY customer_id
),
MonthlyNewCustomers AS (
    SELECT
        DATE_FORMAT(FirstPurchaseDate, '%Y-%m') AS FirstPurchaseMonth,
        COUNT(*) AS TotalNewCustomers
    FROM FirstOrders
    GROUP BY DATE_FORMAT(FirstPurchaseDate, '%Y-%m')
)
SELECT *
FROM MonthlyNewCustomers
ORDER BY FirstPurchaseMonth;

#11 Peak Sales Period Indentification
Select DATE_FORMAT(order_date, '%Y-%m') as Month,
sum(total_amount) as TotalSales
From Orders
Group by DATE_FORMAT(order_date, '%Y-%m')
Order by TotalSales DESC
Limit 3;
