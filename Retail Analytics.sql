-- #1 REMOVING DUPLICATES
-- Step 1: Find duplicate counts
SELECT 
    TransactionID, COUNT(*) 
FROM sales_transaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;

-- Step 2: Create a new table with unique rows
CREATE TABLE sales_transaction_unique AS
SELECT DISTINCT *
FROM sales_transaction;

-- Step 3: Drop original table
DROP TABLE sales_transaction;

-- Step 4: Rename clean table to original name
ALTER TABLE sales_transaction_unique
RENAME TO sales_transaction;

-- Step 5: Display of the new updated table
Select * from sales_transaction;

-- #2 Discrepancies in the price
-- List transactions where transaction price differs from inventory price

SELECT
  s.TransactionID,
  s.Price AS TransactionPrice,
  p.Price AS InventoryPrice
FROM sales_transaction s
JOIN product_inventory p
  ON s.ProductID = p.ProductID
WHERE s.Price <> p.Price;

-- Updating the disceprencies
UPDATE sales_transaction s
JOIN product_inventory p
  ON s.ProductID = p.ProductID
SET s.Price = p.Price
WHERE s.Price <> p.Price;
-- Displaying
SELECT * From sales_transaction;

-- #3 Fixing NULL Values
SELECT 
    (SELECT COUNT(*) 
     FROM customer_profiles 
     WHERE Age IS NULL 
        OR Gender IS NULL 
        OR Location IS NULL 
        OR JoinDate IS NULL) AS 'count(*)';
-- Upadte the Value to unknown        
        
UPDATE customer_profiles
SET 
    Age = COALESCE(Age, 'Unknown'),
    Gender = COALESCE(Gender, 'Unknown'),
    Location = COALESCE(Location, 'Unknown'),
    JoinDate = COALESCE(JoinDate, 'Unknown');
   
SELECT * FROM customer_profiles;

-- #4 Cleaning Date 
-- 1. Create new table with cleaned DATE column

CREATE TABLE sales_transaction_updated AS
SELECT
    TransactionID,
    CustomerID,
    ProductID,
    QuantityPurchased,
    TransactionDate,Price,
    Date_Format(STR_TO_DATE(TransactionDate,'%d/%m/%y'),'%Y-%m-%d') AS TransactionDate_updated
FROM sales_transaction;

-- 2. Drop the old table
DROP TABLE sales_transaction;

-- 3. Rename new table to original name
ALTER TABLE sales_transaction_updated
RENAME TO sales_transaction;

-- 4. Display final cleaned table
SELECT * FROM sales_transaction;

-- #5 Summarize the total sales and quantities sold per product by the company

Select ProductID, sum(QuantityPurchased) as TotalUnitsSold,
Round(Sum(QuantityPurchased*Price),2) as TotalSales
From Sales_transaction
Group by ProductID
Order by TotalSales DESC;

-- #6 Customer Purchase Frequency
Select CustomerID, count(*) as NumberOfTransactions
From Sales_transaction
Group by CustomerID
Order By NumberOfTransactions DESC;

-- #7 Product Categories Performance
Select p.Category, sum(s.QuantityPurchased) as TotalUnitsSold,
sum(s.QuantityPurchased*s.Price) as TotalSales
From Sales_transaction s
Join product_inventory p
on s.ProductID=p.ProductID
Group by Category
Order by TotalSales DESC;

-- #8 High Sales Products
Select ProductID, Sum(QuantityPurchased*Price) as TotalRevenue
From Sales_transaction 
Group by ProductID
Order by TotalRevenue DESC
Limit 10;

-- #9 Low Sales Products
Select ProductID, sum(QuantityPurchased) as TotalUnitsSold
From Sales_transaction
Group by ProductID
Having count(*)>0
Order by TotalUnitsSold asc
Limit 10;

-- #10 Sales Trend
Select TransactionDate_updated as DATETRANS,
count(TransactionID) as Transaction_count, Sum(QuantityPurchased) as TotalUnitsSold,
Sum(QuantityPurchased*Price) as TotalSales
From sales_transaction
Group by TransactionDate_updated
Order by DATETRANS DESC;

-- #11 Growth of Sales
	WITH monthly_sales AS (
		SELECT 
			MONTH(STR_TO_DATE(TransactionDate_updated, '%Y-%m-%d')) AS month,
			ROUND(SUM(QuantityPurchased * Price), 2) AS total_sales
		FROM sales_transaction
		GROUP BY MONTH(STR_TO_DATE(TransactionDate_updated, '%Y-%m-%d'))
	),
	previous_sales AS (
		SELECT
			month,
			total_sales,
			LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales
		FROM monthly_sales
	)

	SELECT
		month,
		total_sales,
		previous_month_sales,
		ROUND(
			CASE
				WHEN previous_month_sales IS NULL THEN NULL
				ELSE ((total_sales - previous_month_sales) / previous_month_sales) * 100
			END
		, 2) AS mom_growth_percentage
	FROM previous_sales
	ORDER BY month;

-- #12 High Purchase Frequency
SELECT 
    CustomerID,
    COUNT(*) AS NumberOfTransactions,
    SUM(QuantityPurchased * Price) AS TotalSpent
FROM sales_transaction
GROUP BY CustomerID
HAVING COUNT(*) > 10
   AND SUM(QuantityPurchased * Price) > 1000
ORDER BY TotalSpent DESC;

-- #13 Occasional Customers
SELECT 
    CustomerID,
    COUNT(*) AS NumberOfTransactions,
    SUM(QuantityPurchased * Price) AS TotalSpent
FROM sales_transaction
Group by CustomerID
Having count(*)<=2
Order by NumberOfTransactions ASC, TotalSpent DESC;

-- #14 Repeat Purchases
Select CustomerID, ProductID,
count(*) as TimesPurchased 
From sales_transaction
Group by CustomerID,ProductID
Having count(*)>1
Order by TimesPurchased DESC;

#15 Loyalty Indicators
SELECT
    CustomerID,
    DATE_FORMAT(MIN(TransactionDate_updated), '%Y-%m-%d') AS FirstPurchase,
    DATE_FORMAT(MAX(TransactionDate_updated), '%Y-%m-%d') AS LastPurchase,
    DATEDIFF(
        MAX(TransactionDate_updated),
        MIN(TransactionDate_updated)
    ) AS DaysBetweenPurchases
FROM sales_transaction
GROUP BY CustomerID
HAVING DaysBetweenPurchases > 0
ORDER BY DaysBetweenPurchases DESC;

#16 Customer Segmentation
-- 1) Create or replace customer_segment table
DROP TABLE IF EXISTS customer_segment;

CREATE TABLE customer_segment AS
SELECT
    cp.CustomerID,
    t.total_quantity AS TotalQuantity,
    CASE
        WHEN t.total_quantity BETWEEN 1 AND 10 THEN 'Low'
        WHEN t.total_quantity BETWEEN 11 AND 30 THEN 'Med'
        WHEN t.total_quantity > 30 THEN 'High'
    END AS CustomerSegment
FROM customer_profiles cp
JOIN (
    SELECT CustomerID, SUM(QuantityPurchased) AS total_quantity
    FROM sales_transaction
    GROUP BY CustomerID
) t ON cp.CustomerID = t.CustomerID;

-- 2) Count customers in each segment
SELECT
    CustomerSegment,
    COUNT(*) 
FROM customer_segment
GROUP BY CustomerSegment;
