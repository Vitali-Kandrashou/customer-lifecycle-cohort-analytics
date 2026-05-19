CREATE VIEW dbo.retention_monthly AS

WITH
RetentionData AS (
	SELECT 
		cohort_month,
		cohort_age_month,
		COUNT(DISTINCT customer_id) AS active_users
	FROM
		dbo.customer_cohort_base
	GROUP BY
		cohort_month,
		cohort_age_month
),

MinMaxDate AS (
	SELECT
		MIN(cohort_month) AS min_date, 
		MAX(cohort_month) AS max_date
	FROM
		RetentionData
),

CohortGrid AS (
	SELECT
		DISTINCT
		rd.cohort_month,
		value AS cohort_age_month
	FROM 
		RetentionData rd
	CROSS JOIN 
		GENERATE_SERIES(0, (SELECT DATEDIFF(MONTH, min_date, max_date) FROM MinMaxDate))
),

FullRetentionData AS (
	SELECT 
		cg.cohort_month,
		cg.cohort_age_month,
		COALESCE(rd.active_users, 0) AS active_users
	FROM 
		CohortGrid cg
	LEFT JOIN
		RetentionData rd
		ON cg.cohort_month = rd.cohort_month
		AND cg.cohort_age_month = rd.cohort_age_month
	CROSS JOIN
		MinMaxDate mmd
	WHERE
		cg.cohort_age_month <= DATEDIFF(MONTH, cg.cohort_month, mmd.max_date)
)

SELECT
	cohort_month,
	cohort_age_month,

	MAX(active_users) OVER (PARTITION BY cohort_month) AS cohort_size,

	active_users,

	ROUND(
		active_users * 1.0 / 
		MAX(active_users) OVER (PARTITION BY cohort_month),
		4
	) AS retention_rate
FROM
	FullRetentionData