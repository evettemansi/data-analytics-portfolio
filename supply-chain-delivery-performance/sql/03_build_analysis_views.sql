USE SupplyChainAnalytics;
GO

GO

CREATE OR ALTER VIEW dbo.vw_LatestReview
AS
WITH RankedReviews AS
(
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,

        ROW_NUMBER() OVER
        (
            PARTITION BY order_id
            ORDER BY
                review_answer_timestamp DESC,
                review_creation_date DESC,
                review_id DESC
        ) AS review_rank

    FROM dbo.vw_Reviews_Clean
)

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM RankedReviews
WHERE review_rank = 1;

GO

SELECT
    COUNT(*) AS LatestReviewRows,
    COUNT(DISTINCT order_id) AS UniqueOrders
FROM dbo.vw_LatestReview;

GO

CREATE OR ALTER VIEW dbo.vw_OrderPayments_Summary
AS
SELECT
    order_id,
    SUM(payment_value) AS total_payment_value,
    COUNT(*) AS payment_transaction_count,
    COUNT(DISTINCT payment_type) AS payment_method_count,
    MAX(payment_installments) AS maximum_installments
FROM dbo.vw_Payments_Clean
GROUP BY order_id;

GO

SELECT
    COUNT(*) AS PaymentSummaryRows,
    COUNT(DISTINCT order_id) AS UniqueOrders,
    SUM(total_payment_value) AS SummaryPaymentTotal
FROM dbo.vw_OrderPayments_Summary;

SELECT
    SUM(payment_value) AS OriginalPaymentTotal
FROM dbo.vw_Payments_Clean;

SELECT
    SUM(payment_value) AS OriginalPaymentTotal
FROM dbo.vw_Payments_Clean;

GO

CREATE OR ALTER VIEW dbo.vw_OrderItems_Summary
AS
SELECT
    order_id,
    COUNT(*) AS item_count,
    COUNT(DISTINCT product_id) AS distinct_product_count,
    COUNT(DISTINCT seller_id) AS seller_count,
    SUM(price) AS total_item_value,
    SUM(freight_value) AS total_freight_value,
    SUM(price + freight_value) AS total_order_item_value
FROM dbo.vw_OrderItems_Clean
GROUP BY order_id;

GO

SELECT
    COUNT(*) AS ItemSummaryRows,
    COUNT(DISTINCT order_id) AS UniqueOrders,
    SUM(item_count) AS OriginalItemRowsRecovered,
    SUM(total_item_value) AS TotalProductValue,
    SUM(total_freight_value) AS TotalFreightValue
FROM dbo.vw_OrderItems_Summary;

GO

CREATE OR ALTER VIEW dbo.vw_OrderPerformance
AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            DAY,
            CAST(o.order_purchase_timestamp AS DATE),
            CAST(o.order_delivered_customer_date AS DATE)
        )
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            DAY,
            CAST(o.order_estimated_delivery_date AS DATE),
            CAST(o.order_delivered_customer_date AS DATE)
        )
        ELSE NULL
    END AS days_from_estimate,

    CASE
        WHEN o.order_status <> 'delivered'
            THEN 'not delivered'
        WHEN o.order_delivered_customer_date IS NULL
            THEN 'unknown'
        WHEN CAST(o.order_delivered_customer_date AS DATE)
           > CAST(o.order_estimated_delivery_date AS DATE)
            THEN 'late'
        ELSE 'on time or early'
    END AS delivery_performance_status,

    CASE
        WHEN o.order_status <> 'delivered'
          OR o.order_delivered_customer_date IS NULL
            THEN NULL
        WHEN CAST(o.order_delivered_customer_date AS DATE)
           > CAST(o.order_estimated_delivery_date AS DATE)
            THEN 1
        ELSE 0
    END AS is_late,

    COALESCE(i.item_count, 0) AS item_count,
    COALESCE(i.distinct_product_count, 0) AS distinct_product_count,
    COALESCE(i.seller_count, 0) AS seller_count,
    COALESCE(i.total_item_value, 0) AS total_item_value,
    COALESCE(i.total_freight_value, 0) AS total_freight_value,
    COALESCE(i.total_order_item_value, 0) AS total_order_item_value,

    p.total_payment_value,
    p.payment_transaction_count,
    p.payment_method_count,
    p.maximum_installments,

    r.review_score

FROM dbo.vw_Orders_Clean AS o

LEFT JOIN dbo.vw_Customers_Clean AS c
    ON o.customer_id = c.customer_id

LEFT JOIN dbo.vw_OrderItems_Summary AS i
    ON o.order_id = i.order_id

LEFT JOIN dbo.vw_OrderPayments_Summary AS p
    ON o.order_id = p.order_id

LEFT JOIN dbo.vw_LatestReview AS r
    ON o.order_id = r.order_id;

GO

SELECT
    COUNT(*) AS PerformanceRows,
    COUNT(DISTINCT order_id) AS UniqueOrders
FROM dbo.vw_OrderPerformance;

SELECT
    delivery_performance_status,
    COUNT(*) AS NumberOfOrders
FROM dbo.vw_OrderPerformance
GROUP BY delivery_performance_status
ORDER BY NumberOfOrders DESC;

GO

CREATE OR ALTER VIEW dbo.vw_ItemDeliveryPerformance
AS
SELECT
    i.order_id,
    i.order_item_id,

    o.customer_unique_id,
    o.customer_city,
    o.customer_state,

    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.delivery_days,
    o.days_from_estimate,
    o.delivery_performance_status,
    o.is_late,

    i.product_id,
    p.product_category_name_english,

    i.seller_id,
    s.seller_city,
    s.seller_state,

    i.shipping_limit_date,
    i.price,
    i.freight_value,
    i.price + i.freight_value AS item_total_value

FROM dbo.vw_OrderItems_Clean AS i

INNER JOIN dbo.vw_OrderPerformance AS o
    ON i.order_id = o.order_id

LEFT JOIN dbo.vw_Products_Clean AS p
    ON i.product_id = p.product_id

LEFT JOIN dbo.vw_Sellers_Clean AS s
    ON i.seller_id = s.seller_id;

GO

SELECT
    COUNT(*) AS ItemRows,
    COUNT(DISTINCT order_id) AS OrdersWithItems,
    SUM(price) AS TotalProductValue,
    SUM(freight_value) AS TotalFreightValue
FROM dbo.vw_ItemDeliveryPerformance;