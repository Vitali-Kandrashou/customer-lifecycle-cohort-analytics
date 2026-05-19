CREATE VIEW dbo.cohort_ltv AS

WITH
LTVData AS (
	SELECT 
		cohort_month,
		cohort_age_month,
		COUNT(DISTINCT customer_id) AS active_users,
		SUM(order_revenue) AS revenue
	FROM
		dbo.customer_cohort_base
	GROUP BY
		cohort_month,
		cohort_age_month
),

CohortSize AS (
	SELECT
		cohort_month,
		active_users as cohort_size
	FROM
		LTVData
	WHERE
		cohort_age_month = 0
),

MinMaxDate AS (
	SELECT
		MIN(cohort_month) AS min_date, 
		MAX(cohort_month) AS max_date
	FROM
		LTVData
),

CohortGrid AS (
	SELECT
		DISTINCT
		ltvd.cohort_month,
		value AS cohort_age_month
	FROM 
		LTVData ltvd
	CROSS JOIN 
		GENERATE_SERIES(0, (SELECT DATEDIFF(MONTH, min_date, max_date) FROM MinMaxDate))
),

FullLTVData AS (
	SELECT 
		cg.cohort_month,
		cg.cohort_age_month,
		cs.cohort_size,
		COALESCE(ltvd.active_users, 0) AS active_users,
		COALESCE(ltvd.revenue, 0) AS revenue
	FROM 
		CohortGrid cg
	LEFT JOIN
		LTVData ltvd
		ON cg.cohort_month = ltvd.cohort_month
		AND cg.cohort_age_month = ltvd.cohort_age_month
	LEFT JOIN	
		CohortSize cs
		ON cg.cohort_month = cs.cohort_month
	CROSS JOIN
		MinMaxDate mmd
	WHERE
		cg.cohort_age_month <= DATEDIFF(MONTH, cg.cohort_month, mmd.max_date)
)

SELECT
	cohort_month,
	cohort_age_month,
	cohort_size,
	revenue,
	revenue * 1.0 / cohort_size AS period_ltv,
	SUM(revenue * 1.0 / cohort_size) OVER (PARTITION BY cohort_month ORDER BY cohort_age_month) AS cumulative_ltv
FROM
	FullLTVData
order by 
	cohort_month,[HumanResources].[vEmployeeDepartment]
	cohort_age_month