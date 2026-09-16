USE SupplyChainAnalytics;
GO

-- 1. Overall order and delivery KPIs

SELECT
    COUNT(*) AS TotalOrders,

    SUM(
        CASE WHEN order_status = 'delivered'
        THEN 1 ELSE 0 END
    ) AS DeliveredOrders,

    SUM(
        CASE WHEN is_late IS NOT NULL
        THEN 1 ELSE 0 END
    ) AS MeasurableDeliveredOrders,

    SUM(
        CASE WHEN is_late = 0
        THEN 1 ELSE 0 END
    ) AS OnTimeOrders,

    SUM(
        CASE WHEN is_late = 1
        THEN 1 ELSE 0 END
    ) AS LateOrders,

    CAST(
        100.0 *
        SUM(CASE WHEN is_late = 0 THEN 1 ELSE 0 END)
        /
        NULLIF(
            SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END),
            0
        )
        AS DECIMAL(5,2)
    ) AS OnTimeDeliveryRatePct,

    CAST(
        AVG(CAST(delivery_days AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays,

    CAST(SUM(total_payment_value) AS DECIMAL(18,2))
        AS TotalRevenue,

    CAST(
        AVG(CAST(review_score AS DECIMAL(10,2)))
        AS DECIMAL(4,2)
    ) AS AverageReviewScore

FROM dbo.vw_OrderPerformance;

-- 2. Dataset date coverage

SELECT
    MIN(order_purchase_timestamp) AS FirstOrderDate,
    MAX(order_purchase_timestamp) AS LastOrderDate
FROM dbo.vw_OrderPerformance;

-- 3. Monthly order-volume check

SELECT
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    ) AS OrderMonth,

    COUNT(*) AS TotalOrders

FROM dbo.vw_OrderPerformance

GROUP BY
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    )

ORDER BY OrderMonth;

-- 4. Monthly delivery-performance trend
-- Reporting period: January 2017 through August 2018

SELECT
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    ) AS OrderMonth,

    COUNT(*) AS TotalOrders,

    SUM(
        CASE WHEN is_late = 1
        THEN 1 ELSE 0 END
    ) AS LateOrders,

    CAST(
        100.0 *
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        /
        NULLIF(
            SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END),
            0
        )
        AS DECIMAL(5,2)
    ) AS LateDeliveryRatePct,

    CAST(
        AVG(CAST(delivery_days AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays,

    CAST(
        SUM(total_payment_value)
        AS DECIMAL(18,2)
    ) AS TotalRevenue

FROM dbo.vw_OrderPerformance

WHERE order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'

GROUP BY
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    )

ORDER BY OrderMonth;

-- 5. Delivery performance by customer state

SELECT
    customer_state,

    COUNT(*) AS TotalOrders,

    SUM(
        CASE WHEN is_late IS NOT NULL
        THEN 1 ELSE 0 END
    ) AS MeasurableDeliveredOrders,

    SUM(
        CASE WHEN is_late = 1
        THEN 1 ELSE 0 END
    ) AS LateOrders,

    CAST(
        100.0 *
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        /
        NULLIF(
            SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END),
            0
        )
        AS DECIMAL(5,2)
    ) AS LateDeliveryRatePct,

    CAST(
        AVG(CAST(delivery_days AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays

FROM dbo.vw_OrderPerformance

WHERE order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'

GROUP BY customer_state

HAVING
    SUM(
        CASE WHEN is_late IS NOT NULL
        THEN 1 ELSE 0 END
    ) >= 100

ORDER BY LateDeliveryRatePct DESC;

-- 6. Seller delivery performance

WITH SellerOrderGrain AS
(
    SELECT DISTINCT
        seller_id,
        seller_state,
        order_id,
        is_late,
        delivery_days
    FROM dbo.vw_ItemDeliveryPerformance
    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp <  '2018-09-01'
)

SELECT
    seller_id,
    seller_state,

    COUNT(*) AS TotalOrders,

    SUM(
        CASE WHEN is_late IS NOT NULL
        THEN 1 ELSE 0 END
    ) AS MeasurableDeliveredOrders,

    SUM(
        CASE WHEN is_late = 1
        THEN 1 ELSE 0 END
    ) AS LateOrders,

    CAST(
        100.0 *
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        /
        NULLIF(
            SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END),
            0
        )
        AS DECIMAL(5,2)
    ) AS LateDeliveryRatePct,

    CAST(
        AVG(CAST(delivery_days AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays

FROM SellerOrderGrain

GROUP BY
    seller_id,
    seller_state

HAVING
    SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END) >= 50

ORDER BY LateDeliveryRatePct DESC;

USE SupplyChainAnalytics;
GO

-- 7. Product-category delivery performance

WITH CategoryOrderGrain AS
(
    SELECT DISTINCT
        product_category_name_english,
        order_id,
        is_late,
        delivery_days
    FROM dbo.vw_ItemDeliveryPerformance
    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp <  '2018-09-01'
)

SELECT
    product_category_name_english AS ProductCategory,

    COUNT(*) AS TotalOrders,

    SUM(
        CASE WHEN is_late IS NOT NULL
        THEN 1 ELSE 0 END
    ) AS MeasurableDeliveredOrders,

    SUM(
        CASE WHEN is_late = 1
        THEN 1 ELSE 0 END
    ) AS LateOrders,

    CAST(
        100.0 *
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        /
        NULLIF(
            SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END),
            0
        )
        AS DECIMAL(5,2)
    ) AS LateDeliveryRatePct,

    CAST(
        AVG(CAST(delivery_days AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays

FROM CategoryOrderGrain

GROUP BY product_category_name_english

HAVING
    SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END) >= 100

ORDER BY LateDeliveryRatePct DESC;

-- 8. Effect of delivery performance on review scores

SELECT
    delivery_performance_status AS DeliveryStatus,

    COUNT(*) AS ReviewedOrders,

    CAST(
        AVG(CAST(review_score AS DECIMAL(10,2)))
        AS DECIMAL(4,2)
    ) AS AverageReviewScore,

    SUM(
        CASE WHEN review_score <= 2
        THEN 1 ELSE 0 END
    ) AS LowScoreReviews,

    CAST(
        100.0 *
        SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)
        /
        COUNT(*)
        AS DECIMAL(5,2)
    ) AS LowScoreReviewRatePct

FROM dbo.vw_OrderPerformance

WHERE is_late IS NOT NULL
  AND review_score IS NOT NULL
  AND order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'

GROUP BY delivery_performance_status

ORDER BY AverageReviewScore DESC;

-- 9. Product-category sales and freight analysis

SELECT
    product_category_name_english AS ProductCategory,

    COUNT(DISTINCT order_id) AS TotalOrders,

    CAST(
        SUM(price)
        AS DECIMAL(18,2)
    ) AS ProductSales,

    CAST(
        SUM(freight_value)
        AS DECIMAL(18,2)
    ) AS FreightCost,

    CAST(
        100.0 * SUM(freight_value)
        /
        NULLIF(SUM(price + freight_value), 0)
        AS DECIMAL(5,2)
    ) AS FreightSharePct

FROM dbo.vw_ItemDeliveryPerformance

WHERE order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'

GROUP BY product_category_name_english

HAVING COUNT(DISTINCT order_id) >= 100

ORDER BY FreightSharePct DESC;

-- 10. Final order-level quality check

SELECT
    COUNT(*) AS TotalOrders,

    COUNT(DISTINCT order_id) AS UniqueOrders,

    SUM(
        CASE WHEN customer_unique_id IS NULL
        THEN 1 ELSE 0 END
    ) AS OrdersWithoutCustomer,

    SUM(
        CASE WHEN item_count = 0
        THEN 1 ELSE 0 END
    ) AS OrdersWithoutItems,

    SUM(
        CASE WHEN total_payment_value IS NULL
        THEN 1 ELSE 0 END
    ) AS OrdersWithoutPayments,

    SUM(
        CASE WHEN review_score IS NULL
        THEN 1 ELSE 0 END
    ) AS OrdersWithoutReviews

FROM dbo.vw_OrderPerformance;