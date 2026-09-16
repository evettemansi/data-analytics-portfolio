USE SupplyChainAnalytics;
GO

SELECT COUNT(*) AS TotalRows
FROM dbo.stg_Customers;

SELECT TOP 10 *
FROM dbo.stg_Customers;

USE SupplyChainAnalytics;
GO

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT order_id) AS UniqueOrders
FROM dbo.stg_Orders;

SELECT
    order_status,
    COUNT(*) AS NumberOfOrders
FROM dbo.stg_Orders
GROUP BY order_status
ORDER BY NumberOfOrders DESC;

SELECT
    COUNT(*) AS TotalItemRows,
    COUNT(DISTINCT order_id) AS OrdersWithItems
FROM dbo.stg_OrderItems;

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS DuplicateCount
FROM dbo.stg_OrderItems
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT product_id) AS UniqueProducts
FROM dbo.stg_Products;

SELECT
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(product_category_name)), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS MissingCategories,
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(product_weight_g)), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS MissingWeights
FROM dbo.stg_Products;

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT seller_id) AS UniqueSellers
FROM dbo.stg_Sellers;

SELECT
    COUNT(*) AS TotalPaymentRows,
    COUNT(DISTINCT order_id) AS OrdersWithPayments
FROM dbo.stg_Payments;

SELECT
    COUNT(*) AS TotalReviewRows,
    COUNT(DISTINCT review_id) AS UniqueReviewIDs,
    COUNT(DISTINCT order_id) AS OrdersWithReviews
FROM dbo.stg_Reviews;

SELECT
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(review_comment_title)), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS MissingTitles,
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(review_comment_message)), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS MissingMessages
FROM dbo.stg_Reviews;

SELECT
    COUNT(*) AS TotalReviews,
    COUNT(NULLIF(LTRIM(RTRIM(review_comment_title)), '')) AS TitlesPresent,
    COUNT(NULLIF(LTRIM(RTRIM(review_comment_message)), '')) AS MessagesPresent
FROM dbo.stg_Reviews;

SELECT
    TRY_CONVERT(INT, review_score) AS ReviewScore,
    COUNT(*) AS NumberOfReviews
FROM dbo.stg_Reviews
GROUP BY TRY_CONVERT(INT, review_score)
ORDER BY ReviewScore;

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT product_category_name) AS UniquePortugueseCategories
FROM dbo.stg_CategoryTranslation;

SELECT TOP 5 *
FROM dbo.stg_CategoryTranslation;

EXEC sp_rename
    'dbo.stg_CategoryTranslation.column1',
    'product_category_name',
    'COLUMN';

EXEC sp_rename
    'dbo.stg_CategoryTranslation.column2',
    'product_category_name_english',
    'COLUMN';

DELETE FROM dbo.stg_CategoryTranslation
WHERE product_category_name = 'product_category_name'
  AND product_category_name_english = 'product_category_name_english';

  SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'stg_CategoryTranslation'
ORDER BY ORDINAL_POSITION;

EXEC sys.sp_rename
    N'dbo.stg_CategoryTranslation.column1',
    N'product_category_name',
    N'COLUMN';
GO

EXEC sys.sp_rename
    N'dbo.stg_CategoryTranslation.column2',
    N'product_category_name_english',
    N'COLUMN';
GO

DELETE FROM dbo.stg_CategoryTranslation
WHERE product_category_name = 'product_category_name'
  AND product_category_name_english = 'product_category_name_english';
GO

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT product_category_name) AS UniquePortugueseCategories
FROM dbo.stg_CategoryTranslation;