USE SupplyChainAnalytics;
GO

SELECT
    COUNT(*) AS TotalOrders,

    COUNT(is_late) AS MeasurableDeliveries,

    SUM(
        CASE
            WHEN is_late = 0 THEN 1
            ELSE 0
        END
    ) AS OnTimeOrders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN is_late = 0 THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(is_late), 0)
        AS DECIMAL(10, 2)
    ) AS OnTimeDeliveryRatePct

FROM dbo.vw_OrderPerformance

WHERE order_purchase_timestamp >= '20170101'
  AND order_purchase_timestamp <  '20180901';

  USE SupplyChainAnalytics;
GO

CREATE OR ALTER VIEW dbo.vw_KPI_Validation
AS
SELECT
    COUNT(*) AS TotalOrders,

    COUNT(is_late) AS MeasurableDeliveries,

    SUM(
        CASE WHEN is_late = 0 THEN 1 ELSE 0 END
    ) AS OnTimeOrders,

    SUM(
        CASE WHEN is_late = 1 THEN 1 ELSE 0 END
    ) AS LateOrders,

    CAST(
        100.0 * SUM(CASE WHEN is_late = 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(is_late), 0)
        AS DECIMAL(10, 2)
    ) AS OnTimeDeliveryRatePct,

    CAST(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(is_late), 0)
        AS DECIMAL(10, 2)
    ) AS LateDeliveryRatePct,
CAST(
    AVG(CAST(delivery_days AS DECIMAL(10, 2)))
    AS DECIMAL(10, 2)
) AS AverageDeliveryDays,

CAST(
    SUM(total_payment_value)
    AS DECIMAL(18, 2)
) AS TotalRevenue,

CAST(
    AVG(CAST(review_score AS DECIMAL(10, 2)))
    AS DECIMAL(10, 2)
) AS AverageReviewScore

FROM dbo.vw_OrderPerformance
WHERE order_purchase_timestamp >= '20170101'
  AND order_purchase_timestamp <  '20180901';
GO