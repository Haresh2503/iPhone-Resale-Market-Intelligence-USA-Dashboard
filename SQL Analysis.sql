SELECT *
FROM iphone_raw
LIMIT 10;
use iphone;

alter table iphone_raw change ï»¿Platform platform varchar(20);

-- check null values--
SELECT
    COUNT(*) AS total_rows,
    SUM(Platform IS NULL OR TRIM(Platform) = '') AS missing_platform,
    SUM(Model IS NULL OR TRIM(Model) = '') AS missing_model,
    SUM(US_States IS NULL OR TRIM(US_States) = '') AS missing_state,
    SUM(City IS NULL OR TRIM(City) = '') AS missing_city,
    SUM(Country IS NULL OR TRIM(Country) = '') AS missing_country,
    SUM(lastUpdated IS NULL OR TRIM(lastUpdated) = '') AS missing_date
FROM iphone_raw;

SELECT *FROM iphone_raw;

-- cleaning/replacing data--
CREATE TABLE iphone_cleaned AS
SELECT
    TRIM(Platform) AS Platform,
    TRIM(Model) AS Model,
    TRIM(Model_family) AS Model_family,
    CAST(Generation_number AS UNSIGNED) AS Generation_number,
    CASE
        WHEN LOWER(TRIM(is_pro)) IN ('true', '1', 'yes') THEN 1
        ELSE 0
    END AS is_pro,
    TRIM(Storage_options_gb) AS Storage_options_gb,
    CAST(Storage_gb_numeric AS UNSIGNED) AS Storage_gb_numeric,
    TRIM(`Condition`) AS `Condition`,
    CAST(
        REPLACE(REPLACE(TRIM(Price), '$', ''), ',', '')
        AS DECIMAL(10,2)
    ) AS Price,
    CASE
        WHEN WasPrice IS NULL OR TRIM(WasPrice) = '' THEN NULL
        ELSE CAST(
            REPLACE(REPLACE(TRIM(WasPrice), '$', ''), ',', '')
            AS DECIMAL(10,2)
        )
    END AS WasPrice,
    CASE
        WHEN LOWER(TRIM(Price_Discount_pct)) = 'no discount'
             OR TRIM(Price_Discount_pct) = ''
        THEN 0
        ELSE CAST(TRIM(Price_Discount_pct) AS DECIMAL(10,2))
    END AS Price_Discount_pct,
    CAST(Available AS UNSIGNED) AS Available,
    CAST(Sold AS UNSIGNED) AS Sold,
    TRIM(Seller) AS Seller,
    TRIM(itemLocation) AS itemLocation,
    NULLIF(TRIM(City), '') AS City,
    NULLIF(TRIM(US_States), '') AS US_State,
    CASE
        WHEN LOWER(TRIM(Country)) = 'china' THEN 'China'
        WHEN LOWER(TRIM(Country)) = 'united states' THEN 'United States'
        WHEN LOWER(TRIM(Country)) = 'canada' THEN 'Canada'
        WHEN LOWER(TRIM(Country)) = 'australia' THEN 'Australia'
        WHEN LOWER(TRIM(Country)) = 'south korea' THEN 'South Korea'
        WHEN LOWER(TRIM(Country)) = 'united kingdom' THEN 'United Kingdom'
        WHEN LOWER(TRIM(Country)) = 'malaysia' THEN 'Malaysia'
        ELSE NULLIF(TRIM(Country), '')
    END AS Country,
    CASE
        WHEN TRIM(lastUpdated) = '' THEN NULL
        ELSE STR_TO_DATE(TRIM(lastUpdated), '%d-%m-%Y')
    END AS Last_Updated,
    TRIM(Month) AS Month,
    CAST(Year AS UNSIGNED) AS Year,
    CAST(
        REPLACE(REPLACE(TRIM(Revenue), '$', ''), ',', '')
        AS DECIMAL(12,2)
    ) AS Revenue
FROM iphone_raw;

DESCRIBE iphone_cleaned;

-- Checking for remaining NULLs --
SELECT
    COUNT(*) AS total_rows,
    SUM(Price IS NULL) AS missing_price,
    SUM(WasPrice IS NULL) AS missing_was_price,
    SUM(City IS NULL) AS missing_city,
    SUM(US_State IS NULL) AS missing_state,
    SUM(Country IS NULL) AS missing_country,
    SUM(Last_Updated IS NULL) AS missing_date
FROM iphone_cleaned;

-- Checking for duplicate records --
SELECT
    Model,
    Seller,
    Price,
    Sold,
    COUNT(*) AS duplicate_count
FROM iphone_cleaned
GROUP BY
    Model,
    Seller,
    Price,
    Sold
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Checking invalid numeric values --
SELECT *
FROM iphone_cleaned
WHERE Price <= 0;

SELECT *
FROM iphone_cleaned
WHERE Sold < 0;

SELECT *
FROM iphone_cleaned
WHERE Available < 0;

SELECT *
FROM iphone_cleaned
WHERE Revenue < 0;

-- Checking whether Revenue makes sense --
SELECT
    Model,
    Price,
    Sold,
    Revenue,
    ROUND(Price * Sold, 2) AS Calculated_Revenue
FROM iphone_cleaned
WHERE ROUND(Price * Sold, 2) <> Revenue;

-- calculate the difference: --
SELECT
    SUM(ABS(Revenue - (Price * Sold))) AS revenue_difference
FROM iphone_cleaned;

-- checking count of countries -- 
SELECT
    Country,
    COUNT(*) AS listings
FROM iphone_cleaned
GROUP BY Country
ORDER BY listings DESC;

-- creating a US-only table --
CREATE TABLE iphone_usa AS
SELECT *
FROM iphone_cleaned
WHERE Country = 'United States';

SELECT COUNT(*) AS usa_records
FROM iphone_usa;

-- Top-selling iPhone models --
SELECT
    Model_family,
    SUM(Sold) AS Total_Sold
FROM iphone_usa
GROUP BY Model_family
ORDER BY Total_Sold DESC;

-- Revenue by model --
SELECT
    Model_family,
    SUM(Revenue) AS Total_Revenue
FROM iphone_usa
GROUP BY Model_family
ORDER BY Total_Revenue DESC;

-- Average price by model --
SELECT
    Model_family,
    ROUND(AVG(Price), 2) AS Average_Price
FROM iphone_usa
GROUP BY Model_family
ORDER BY Average_Price DESC;

-- Sales by storage 
SELECT
    Storage_gb_numeric,
    SUM(Sold) AS Total_Sold,
    SUM(Revenue) AS Total_Revenue
FROM iphone_usa
GROUP BY Storage_gb_numeric
ORDER BY Total_Sold DESC;

