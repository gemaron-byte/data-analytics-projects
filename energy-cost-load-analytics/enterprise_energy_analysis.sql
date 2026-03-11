-- ============================================================
-- Enterprise Energy Cost & Load Analytics
-- Author: Gemaron | Flying Gem Consulting LLC
-- Dataset: 5-site data center portfolio | Full Year 2024
-- Table:   fact_energy_daily
-- ============================================================
-- Columns:
--   site_id            : Facility identifier (e.g., DC_NJ_01)
--   date               : Daily record date
--   region             : Geographic region
--   utility_provider   : Utility company (PSE&G, Oncor, PG&E, ComEd, Puget Sound Energy)
--   rate_class         : Tariff structure (TOU, Industrial Demand, etc.)
--   energy_mwh         : Daily energy consumption in megawatt-hours
--   peak_demand_mw     : Daily peak demand in megawatts
--   energy_charge_usd  : Daily energy charge in USD
--   demand_charge_usd  : Daily demand charge in USD
--   total_cost_usd     : Total daily cost (energy + demand)
-- ============================================================


-- ============================================================
-- QUERY 01 | Monthly Cost Rollup by Site
-- Business question: What did each site spend per month,
-- broken out by energy vs. demand charges?
-- ============================================================

WITH monthly_cost AS (
    SELECT
        site_id,
        DATE_TRUNC('month', date) AS month,
        SUM(energy_mwh)          AS total_mwh,
        SUM(energy_charge_usd)   AS energy_cost,
        SUM(demand_charge_usd)   AS demand_cost,
        SUM(total_cost_usd)      AS total_cost
    FROM fact_energy_daily
    GROUP BY 1, 2
)
SELECT *
FROM monthly_cost
ORDER BY site_id, month;


-- ============================================================
-- QUERY 02 | Month-Over-Month Cost Variance by Site
-- Business question: How much did each site's cost change
-- month-over-month, and by what percentage?
-- Window function: LAG() partitioned by site
-- ============================================================

WITH monthly_cost AS (
    SELECT
        site_id,
        DATE_TRUNC('month', date) AS month,
        SUM(total_cost_usd)       AS total_cost
    FROM fact_energy_daily
    GROUP BY 1, 2
)
SELECT
    site_id,
    month,
    total_cost,
    LAG(total_cost) OVER (PARTITION BY site_id ORDER BY month) AS prior_month_cost,
    ROUND(
        (total_cost - LAG(total_cost) OVER (PARTITION BY site_id ORDER BY month))
        / NULLIF(LAG(total_cost) OVER (PARTITION BY site_id ORDER BY month), 0)
        * 100,
        2
    ) AS mom_percent_change
FROM monthly_cost
ORDER BY site_id, month;


-- ============================================================
-- QUERY 03 | Demand Charge as % of Total Cost by Site
-- Business question: Which sites are most exposed to demand
-- charges — the largest and least controllable cost driver?
-- Key finding: Demand charges represent ~90% of portfolio cost
-- ============================================================

SELECT
    site_id,
    ROUND(
        SUM(demand_charge_usd) / NULLIF(SUM(total_cost_usd), 0) * 100,
        2
    ) AS demand_cost_percent
FROM fact_energy_daily
GROUP BY site_id
ORDER BY demand_cost_percent DESC;


-- ============================================================
-- QUERY 04 | Monthly Peak Demand Ranking Across Sites
-- Business question: Which site drives the highest peak demand
-- each month — and how does that ranking shift over time?
-- Window function: RANK() partitioned by month
-- ============================================================

WITH monthly_peak AS (
    SELECT
        site_id,
        DATE_TRUNC('month', date) AS month,
        MAX(peak_demand_mw)       AS max_peak_mw
    FROM fact_energy_daily
    GROUP BY 1, 2
)
SELECT
    month,
    site_id,
    max_peak_mw,
    RANK() OVER (PARTITION BY month ORDER BY max_peak_mw DESC) AS peak_rank
FROM monthly_peak
ORDER BY month, peak_rank;


-- ============================================================
-- QUERY 05 | 30-Day Rolling Average Cost by Site
-- Business question: What is the smoothed cost trend for each
-- site, removing day-to-day noise?
-- Window function: Rolling average using ROWS BETWEEN
-- ============================================================

SELECT
    site_id,
    date,
    total_cost_usd,
    ROUND(
        AVG(total_cost_usd) OVER (
            PARTITION BY site_id
            ORDER BY date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_30_day_avg
FROM fact_energy_daily
ORDER BY site_id, date;


-- ============================================================
-- QUERY 06 | Cost Volatility by Site (Standard Deviation)
-- Business question: Which sites carry the highest financial
-- risk due to unpredictable daily energy costs?
-- ============================================================

SELECT
    site_id,
    ROUND(STDDEV(total_cost_usd), 2) AS cost_volatility
FROM fact_energy_daily
GROUP BY site_id
ORDER BY cost_volatility DESC;


-- ============================================================
-- QUERY 07 | Data Integrity Validation
-- Business question: Are there records where energy + demand
-- charges do not reconcile to the reported total cost?
-- Tolerance: $1.00 — flags potential billing or ETL errors
-- ============================================================

SELECT
    site_id,
    date,
    energy_charge_usd,
    demand_charge_usd,
    total_cost_usd,
    (energy_charge_usd + demand_charge_usd) AS recalculated_total
FROM fact_energy_daily
WHERE ABS(
    total_cost_usd - (energy_charge_usd + demand_charge_usd)
) > 1
ORDER BY date;


-- ============================================================
-- QUERY 08 | Top 10 Highest Single-Day Cost Events
-- Business question: What were the most expensive individual
-- days across the entire portfolio, and which sites drove them?
-- ============================================================

SELECT
    site_id,
    date,
    total_cost_usd
FROM fact_energy_daily
ORDER BY total_cost_usd DESC
LIMIT 10;


-- ============================================================
-- QUERY 09 | Monthly Energy Consumption & Cost Summary by Site
-- Business question: How does monthly volume (MWh) correlate
-- with total and average daily cost per site?
-- Operational use: Core monthly reporting dashboard query
-- ============================================================

SELECT
    site_id,
    DATE_TRUNC('month', date) AS month,
    SUM(energy_mwh)           AS total_mwh,
    SUM(total_cost_usd)       AS total_cost,
    ROUND(AVG(total_cost_usd), 2) AS avg_daily_cost
FROM fact_energy_daily
GROUP BY 1, 2
ORDER BY site_id, month;


-- ============================================================
-- QUERY 10 | Trailing 3-Month Portfolio Cost Average
-- Business question: What is the smoothed quarterly cost trend
-- for the entire portfolio — the executive-level spend view?
-- Window function: Rolling 3-month avg across full portfolio
-- ============================================================

WITH monthly_cost AS (
    SELECT
        DATE_TRUNC('month', date) AS month,
        SUM(total_cost_usd)       AS total_cost
    FROM fact_energy_daily
    GROUP BY 1
)
SELECT
    month,
    total_cost,
    ROUND(
        AVG(total_cost) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS trailing_3_month_avg
FROM monthly_cost
ORDER BY month;
