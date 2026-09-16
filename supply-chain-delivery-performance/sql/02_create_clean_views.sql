USE SupplyChainAnalytics;
GO

CREATE OR ALTER VIEW dbo.vw_Orders_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(order_id)), '') AS order_id,
    NULLIF(LTRIM(RTRIM(customer_id)), '') AS customer_id,
    LOWER(NULLIF(LTRIM(RTRIM(order_status)), '')) AS order_status,

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), '')
    ) AS order_purchase_timestamp,

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_approved_at)), '')
    ) AS order_approved_at,

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), '')
    ) AS order_delivered_carrier_date,

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '')
    ) AS order_delivered_customer_date,

    TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '')
    ) AS order_estimated_delivery_date

FROM dbo.stg_Orders;
GO

SELECT TOP 10 *
FROM dbo.vw_Orders_Clean;

SELECT
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END)
        AS MissingPurchaseDates,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)
        AS MissingDeliveredDates,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END)
        AS MissingEstimatedDates
FROM dbo.vw_Orders_Clean;

SELECT
    order_status,
    COUNT(*) AS TotalOrders,
    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingDeliveredDates
FROM dbo.vw_Orders_Clean
GROUP BY order_status
ORDER BY MissingDeliveredDates DESC;
GO

CREATE OR ALTER VIEW dbo.vw_Customers_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(customer_id)), '') AS customer_id,
    NULLIF(LTRIM(RTRIM(customer_unique_id)), '') AS customer_unique_id,
    NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), '') AS customer_zip_code_prefix,
    LOWER(NULLIF(LTRIM(RTRIM(customer_city)), '')) AS customer_city,
    UPPER(NULLIF(LTRIM(RTRIM(customer_state)), '')) AS customer_state
FROM dbo.stg_Customers;

GO

SELECT
    COUNT(*) AS CustomerRows,
    COUNT(DISTINCT customer_id) AS UniqueCustomerIDs,
    COUNT(DISTINCT customer_unique_id) AS ActualUniqueCustomers
FROM dbo.vw_Customers_Clean;

GO

CREATE OR ALTER VIEW dbo.vw_OrderItems_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(order_id)), '') AS order_id,
    TRY_CONVERT(INT, order_item_id) AS order_item_id,
    NULLIF(LTRIM(RTRIM(product_id)), '') AS product_id,
    NULLIF(LTRIM(RTRIM(seller_id)), '') AS seller_id,
    TRY_CONVERT(DATETIME2(0), shipping_limit_date) AS shipping_limit_date,
    TRY_CONVERT(DECIMAL(12,2), price) AS price,
    TRY_CONVERT(DECIMAL(12,2), freight_value) AS freight_value
FROM dbo.stg_OrderItems;

GO

SELECT
    COUNT(*) AS ItemRows,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS InvalidItemIDs,
    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS InvalidShippingDates,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS InvalidPrices,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS InvalidFreightValues
FROM dbo.vw_OrderItems_Clean;

GO

CREATE OR ALTER VIEW dbo.vw_Products_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(p.product_id)), '') AS product_id,

    NULLIF(
        LTRIM(RTRIM(p.product_category_name)),
        ''
    ) AS product_category_name_portuguese,

    COALESCE(
        NULLIF(LTRIM(RTRIM(t.product_category_name_english)), ''),
        'unknown'
    ) AS product_category_name_english,

    TRY_CONVERT(INT, p.product_name_lenght) AS product_name_length,
    TRY_CONVERT(INT, p.product_description_lenght) AS product_description_length,
    TRY_CONVERT(INT, p.product_photos_qty) AS product_photos_quantity,
    TRY_CONVERT(DECIMAL(12,2), p.product_weight_g) AS product_weight_g,
    TRY_CONVERT(DECIMAL(12,2), p.product_length_cm) AS product_length_cm,
    TRY_CONVERT(DECIMAL(12,2), p.product_height_cm) AS product_height_cm,
    TRY_CONVERT(DECIMAL(12,2), p.product_width_cm) AS product_width_cm

FROM dbo.stg_Products AS p
LEFT JOIN dbo.stg_CategoryTranslation AS t
    ON LTRIM(RTRIM(p.product_category_name))
     = LTRIM(RTRIM(t.product_category_name));

GO

SELECT
    COUNT(*) AS ProductRows,
    COUNT(DISTINCT product_id) AS UniqueProducts,
    SUM(
        CASE WHEN product_category_name_english = 'unknown'
        THEN 1 ELSE 0 END
    ) AS UnknownCategories,
    SUM(
        CASE WHEN product_weight_g IS NULL
        THEN 1 ELSE 0 END
    ) AS MissingWeights
FROM dbo.vw_Products_Clean;

SELECT
    product_category_name_portuguese,
    COUNT(*) AS ProductCount
FROM dbo.vw_Products_Clean
WHERE product_category_name_english = 'unknown'
  AND product_category_name_portuguese IS NOT NULL
GROUP BY product_category_name_portuguese
ORDER BY ProductCount DESC;

GO

CREATE OR ALTER VIEW dbo.vw_Sellers_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(seller_id)), '') AS seller_id,
    NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), '') AS seller_zip_code_prefix,
    LOWER(NULLIF(LTRIM(RTRIM(seller_city)), '')) AS seller_city,
    UPPER(NULLIF(LTRIM(RTRIM(seller_state)), '')) AS seller_state
FROM dbo.stg_Sellers;

GO

SELECT
    COUNT(*) AS SellerRows,
    COUNT(DISTINCT seller_id) AS UniqueSellers,
    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS MissingStates
FROM dbo.vw_Sellers_Clean;

GO

CREATE OR ALTER VIEW dbo.vw_Payments_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(order_id)), '') AS order_id,
    TRY_CONVERT(INT, payment_sequential) AS payment_sequential,
    LOWER(NULLIF(LTRIM(RTRIM(payment_type)), '')) AS payment_type,
    TRY_CONVERT(INT, payment_installments) AS payment_installments,
    TRY_CONVERT(DECIMAL(12,2), payment_value) AS payment_value
FROM dbo.stg_Payments;

GO

USE SupplyChainAnalytics;
GO

CREATE OR ALTER VIEW dbo.vw_Payments_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(order_id)), '') AS order_id,
    TRY_CONVERT(INT, payment_sequential) AS payment_sequential,
    LOWER(NULLIF(LTRIM(RTRIM(payment_type)), '')) AS payment_type,
    TRY_CONVERT(INT, payment_installments) AS payment_installments,
    TRY_CONVERT(DECIMAL(12,2), payment_value) AS payment_value
FROM dbo.stg_Payments;
GO

SELECT
    COUNT(*) AS PaymentRows,
    COUNT(DISTINCT order_id) AS OrdersWithPayments,
    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END)
        AS InvalidPaymentSequence,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END)
        AS InvalidInstallments,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END)
        AS InvalidPaymentValues
FROM dbo.vw_Payments_Clean;

GO

CREATE OR ALTER VIEW dbo.vw_Reviews_Clean
AS
SELECT
    NULLIF(LTRIM(RTRIM(review_id)), '') AS review_id,
    NULLIF(LTRIM(RTRIM(order_id)), '') AS order_id,
    TRY_CONVERT(INT, review_score) AS review_score,
    NULLIF(LTRIM(RTRIM(review_comment_title)), '') AS review_comment_title,
    NULLIF(LTRIM(RTRIM(review_comment_message)), '') AS review_comment_message,
    TRY_CONVERT(DATETIME2(0), review_creation_date) AS review_creation_date,
    TRY_CONVERT(DATETIME2(0), review_answer_timestamp) AS review_answer_timestamp
FROM dbo.stg_Reviews;

GO

SELECT
    COUNT(*) AS ReviewRows,
    COUNT(DISTINCT order_id) AS OrdersWithReviews,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END)
        AS InvalidReviewScores,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END)
        AS InvalidCreationDates,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END)
        AS InvalidAnswerDates
FROM dbo.vw_Reviews_Clean;