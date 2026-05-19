CREATE VIEW dbo.customer_cohort_base AS

WITH orders AS (
	SELECT
		CustomerID AS customer_id,

		SalesOrderID AS order_id,

		TotalDue AS order_revenue,

		CAST(OrderDate AS DATE) AS order_date,

		CAST(
			MIN(OrderDate) OVER (PARTITION BY CustomerID) 
			AS DATE
		) AS first_order_date

	FROM
		Sales.SalesOrderHeader
)

SELECT
	customer_id,

	order_id,

	order_revenue,

	first_order_date,

	order_date,

	DATETRUNC(MONTH, order_date) AS order_month,

	DATETRUNC(MONTH, first_order_date) AS cohort_month,

	DATEDIFF(
		MONTH, 
		DATETRUNC(MONTH, first_order_date), 
		DATETRUNC(MONTH, order_date)
	) AS cohort_age_month,

	FLOOR(
		DATEDIFF(DAY, first_order_date, order_date) / 30.0
	) AS cohort_age_30d
FROM
	orders