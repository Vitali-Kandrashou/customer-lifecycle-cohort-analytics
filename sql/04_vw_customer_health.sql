CREATE VIEW dbo.customer_health AS	

WITH MaxDate AS (	
	SELECT 
		MAX(order_date) AS max_date
	FROM
		dbo.customer_cohort_base
)

SELECT
	customer_id,
	MAX(cohort_month) AS cohort_month,
	MAX(order_date) AS last_order_date,
	DATEDIFF(DAY, MAX(order_date), m.max_date) AS days_since_last_purchase,
	DATEDIFF(DAY, MIN(order_date), MAX(order_date)) AS customer_lifespan_days,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(order_revenue) AS total_revenue
FROM
	dbo.customer_cohort_base
CROSS JOIN MaxDate m
GROUP BY 
	customer_id,
	m.max_date