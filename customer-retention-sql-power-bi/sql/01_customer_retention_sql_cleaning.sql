/*
Customer Retention Analytics — SQL Data Preparation
Purpose: Audit the imported raw customer data and create a clean view for Power BI.
Raw source: dbo.Customer_Retention_Raw
Power BI source: dbo.vw_Customer_Retention_Clean
*/

USE CustomerRetentionDB;
GO

-- 1. Verify row count and customer ID uniqueness.
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Customer_ID) AS Unique_Customers,
    COUNT(*) - COUNT(DISTINCT Customer_ID) AS Duplicate_Customer_IDs
FROM dbo.Customer_Retention_Raw;

-- 2. Check important fields for missing values.
SELECT
    SUM(CASE WHEN Customer_ID IS NULL
                  OR LTRIM(RTRIM(Customer_ID)) = ''
             THEN 1 ELSE 0 END) AS Missing_Customer_ID,
    SUM(CASE WHEN Signup_Date IS NULL
             THEN 1 ELSE 0 END) AS Missing_Signup_Date,
    SUM(CASE WHEN Last_Purchase_Date IS NULL
             THEN 1 ELSE 0 END) AS Missing_Last_Purchase_Date,
    SUM(CASE WHEN Region IS NULL
                  OR LTRIM(RTRIM(Region)) = ''
             THEN 1 ELSE 0 END) AS Missing_Region
FROM dbo.Customer_Retention_Raw;

-- 3. Count logically invalid date records.
SELECT COUNT(*) AS Invalid_Date_Records
FROM dbo.Customer_Retention_Raw
WHERE Signup_Date > Last_Purchase_Date;

-- 4. Validate order values after converting imported text to integers.
SELECT COUNT(*) AS Invalid_Order_Records
FROM dbo.Customer_Retention_Raw
WHERE TRY_CAST(Total_Orders AS INT) IS NULL
   OR TRY_CAST(Repeat_Orders AS INT) IS NULL
   OR TRY_CAST(Total_Orders AS INT) < 1
   OR TRY_CAST(Repeat_Orders AS INT) < 0
   OR TRY_CAST(Repeat_Orders AS INT) > TRY_CAST(Total_Orders AS INT);

-- 5. Validate revenue, discount, and net sales calculations.
SELECT COUNT(*) AS Invalid_Sales_Records
FROM dbo.Customer_Retention_Raw
WHERE Total_Revenue < 0
   OR Discount_Amount < 0
   OR Net_Sales < 0
   OR Discount_Amount > Total_Revenue
   OR ABS((Total_Revenue - Discount_Amount) - Net_Sales) > 0.01;
GO

-- 6. Create the cleaned view used by Power BI.
CREATE OR ALTER VIEW dbo.vw_Customer_Retention_Clean AS
SELECT
    LTRIM(RTRIM(Customer_ID)) AS Customer_ID,
    CAST(Signup_Date AS DATE) AS Signup_Date,
    CAST(Last_Purchase_Date AS DATE) AS Last_Purchase_Date,
    LTRIM(RTRIM(Region)) AS Region,
    LTRIM(RTRIM(Acquisition_Channel)) AS Acquisition_Channel,
    LTRIM(RTRIM(Customer_Group)) AS Customer_Group,
    LTRIM(RTRIM(Loyalty_Status)) AS Loyalty_Status,
    TRY_CAST(Total_Orders AS INT) AS Total_Orders,
    TRY_CAST(Repeat_Orders AS INT) AS Repeat_Orders,
    CAST(Total_Revenue AS DECIMAL(12,2)) AS Total_Revenue,
    CAST(Discount_Amount AS DECIMAL(12,2)) AS Discount_Amount,
    CAST(Net_Sales AS DECIMAL(12,2)) AS Net_Sales,
    CAST(Satisfaction_Score AS INT) AS Satisfaction_Score,
    CAST(Days_Since_Last_Purchase AS INT) AS Days_Since_Last_Purchase,
    LTRIM(RTRIM(Retention_Status)) AS Retention_Status,
    LTRIM(RTRIM(Churn_Risk)) AS Churn_Risk
FROM dbo.Customer_Retention_Raw
WHERE Signup_Date <= Last_Purchase_Date
  AND TRY_CAST(Total_Orders AS INT) IS NOT NULL
  AND TRY_CAST(Repeat_Orders AS INT) IS NOT NULL;
GO

-- 7. Verify the raw, excluded, and clean record counts.
SELECT
    (SELECT COUNT(*)
     FROM dbo.Customer_Retention_Raw) AS Raw_Records,
    (SELECT COUNT(*)
     FROM dbo.Customer_Retention_Raw
     WHERE Signup_Date > Last_Purchase_Date) AS Excluded_Invalid_Date_Records,
    (SELECT COUNT(*)
     FROM dbo.vw_Customer_Retention_Clean) AS Clean_Records;

