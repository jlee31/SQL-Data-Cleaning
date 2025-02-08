# Analyzing https://www.kaggle.com/datasets/hosammhmdali/supermarket-sales/data

-- Select all data from the original table
SELECT * 
FROM supermarket_sales.sales;

-- Create a staging table
CREATE TABLE supermarket_sales.sales_staging 
LIKE supermarket_sales.sales;

-- Insert data into the staging table
INSERT INTO supermarket_sales.sales_staging 
SELECT * FROM supermarket_sales.sales;

-- 1. Remove Duplicates

-- Check for duplicates
SELECT *
FROM supermarket_sales.sales_staging;

-- Identify duplicates using ROW_NUMBER()
SELECT `Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`,
    ROW_NUMBER() OVER (
        PARTITION BY `Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`
    ) AS row_num
FROM supermarket_sales.sales_staging;

-- View duplicates
SELECT *
FROM (
    SELECT `Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`,
        ROW_NUMBER() OVER (
            PARTITION BY `Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`
        ) AS row_num
    FROM supermarket_sales.sales_staging
) duplicates
WHERE row_num > 1;

-- Delete duplicates
WITH DELETE_CTE AS (
    SELECT `Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`,
        ROW_NUMBER() OVER (
            PARTITION BY `Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`
        ) AS row_num
    FROM supermarket_sales.sales_staging
)
DELETE FROM supermarket_sales.sales_staging
WHERE (`Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`, row_num) IN (
    SELECT `Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`, `Unit price`, `Quantity`, `Tax`, `Total`, `Date`, `Time`, `Payment`, `cogs`, `gross margin percentage`, `gross income`, `Rating`, row_num
    FROM DELETE_CTE
) AND row_num > 1;

-- 2. Standardize Data

-- Check for null or empty values in specific columns
SELECT DISTINCT `Product line`
FROM supermarket_sales.sales_staging
ORDER BY `Product line`;

-- Update null or empty values
UPDATE supermarket_sales.sales_staging
SET `Product line` = NULL
WHERE `Product line` = '';

-- Populate null values using self-join
UPDATE sales_staging t1
JOIN sales_staging t2
ON t1.`Invoice ID` = t2.`Invoice ID`
SET t1.`Product line` = t2.`Product line`
WHERE t1.`Product line` IS NULL
AND t2.`Product line` IS NOT NULL;

-- Standardize specific values (e.g., Payment method)
UPDATE supermarket_sales.sales_staging
SET `Payment` = 'Credit Card'
WHERE `Payment` IN ('Credit', 'Credit card');

-- Trim trailing characters from City names
UPDATE supermarket_sales.sales_staging
SET `City` = TRIM(TRAILING '.' FROM `City`);

-- Convert Date format
UPDATE supermarket_sales.sales_staging
SET `Date` = STR_TO_DATE(`Date`, '%m/%d/%Y');

-- Modify column data type
ALTER TABLE supermarket_sales.sales_staging
MODIFY COLUMN `Date` DATE;

-- 3. Look at Null Values

-- Check for null values in specific columns
SELECT *
FROM supermarket_sales.sales_staging
WHERE `Quantity` IS NULL;

-- Delete rows with null values in specific columns
DELETE FROM supermarket_sales.sales_staging
WHERE `Quantity` IS NULL
AND `Total` IS NULL;

-- 4. Remove Unnecessary Columns

-- Drop the row_num column (if added earlier)
ALTER TABLE supermarket_sales.sales_staging
DROP COLUMN row_num;

-- Final cleaned dataset
SELECT * 
FROM supermarket_sales.sales_staging;
