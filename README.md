# Enterprise Energy Cost & Load Analytics

**SQL-heavy. Operationally grounded. Finance-facing. Data center–ready.**

A full-year (2024) energy cost and load analysis across a 5-site enterprise data center portfolio, spanning four U.S. regions and five utility providers. This project demonstrates applied SQL for operational finance — demand charge analysis, cost volatility, peak load ranking, and billing integrity validation.

---

## Portfolio Overview

| Site | Region | Utility Provider | Rate Class | 2024 Total Cost |
|---|---|---|---|---|
| DC_NJ_01 | Northeast | PSE&G | Large Commercial TOU | $48.3M |
| DC_IL_05 | Midwest | ComEd | Industrial Demand | $42.6M |
| DC_WA_04 | West | Puget Sound Energy | Large Load Service | $40.7M |
| DC_CA_03 | West | PG&E | Primary General | $38.5M |
| DC_TX_02 | South | Oncor | GS-3 TOU | $34.2M |

**Portfolio total: $204.4M in energy costs across 230M+ kWh consumed**

---

## Key Finding

> **Demand charges account for 90.4% of total portfolio cost.**

In large commercial and industrial utility accounts, demand charges — billed on peak kilowatt draw rather than total consumption — routinely dominate the bill. This analysis quantifies that exposure across five sites and five rate structures, and surfaces which sites carry the highest financial risk.

This is the central operational insight this project is built around.

---

## Dataset

| Field | Description |
|---|---|
| `date` | Daily record (Jan 1 – Dec 31, 2024) |
| `site_id` | Facility identifier |
| `region` | Geographic region |
| `utility_provider` | Utility company |
| `rate_class` | Tariff/rate structure |
| `energy_mwh` | Daily consumption in megawatt-hours |
| `peak_demand_mw` | Daily peak demand in megawatts |
| `energy_charge_usd` | Daily energy charge |
| `demand_charge_usd` | Daily demand charge |
| `total_cost_usd` | Total daily cost |

**1,830 daily records | 5 sites | 12 months | 4 regions**

---

## SQL Analysis — 10 Queries

### Query 01 — Monthly Cost Rollup by Site
Aggregates energy vs. demand charges monthly per site using a CTE.
Foundation query for all downstream trend analysis.

### Query 02 — Month-Over-Month Cost Variance
Calculates MoM cost change and percentage shift per site using `LAG()` window function.
Finance-facing: surfaces cost acceleration and seasonal patterns.

### Query 03 — Demand Charge as % of Total Cost
Ranks sites by demand charge exposure.
Drives the headline finding: demand charges = 90.4% of portfolio spend.

### Query 04 — Monthly Peak Demand Ranking
Uses `RANK()` to identify which site drives the highest peak demand each month.
Supports demand response targeting and capacity planning.

### Query 05 — 30-Day Rolling Average Cost
Smooths daily cost volatility per site using a `ROWS BETWEEN 29 PRECEDING AND CURRENT ROW` window frame.
Reveals true cost trend direction beneath daily noise.

### Query 06 — Cost Volatility by Site
Applies `STDDEV()` to rank sites by financial risk.
High volatility = unpredictable billing = harder to budget.

### Query 07 — Data Integrity Validation
Flags records where `energy_charge + demand_charge` does not reconcile to `total_cost` within a $1 tolerance.
An auditor's check — verifying the data before trusting the analysis.

### Query 08 — Top 10 Highest Single-Day Cost Events
Surfaces worst-day outliers across the full portfolio.
Entry point for anomaly investigation and budget spike attribution.

### Query 09 — Monthly Energy & Cost Summary
Combines MWh volume with total and average daily cost per site per month.
Core operational dashboard query — what a site manager pulls every month.

### Query 10 — Trailing 3-Month Portfolio Average
Executive-level smoothed spend view across the full portfolio using a 3-month rolling window.
Removes seasonal noise for board-level or CFO reporting.

---

## SQL Techniques Demonstrated

- Common Table Expressions (CTEs)
- Window functions: `LAG()`, `RANK()`, `AVG() OVER`, `ROWS BETWEEN`
- Aggregate functions: `SUM()`, `AVG()`, `MAX()`, `STDDEV()`
- `NULLIF()` for safe division
- `DATE_TRUNC()` for time-series aggregation
- Data validation logic using `ABS()` tolerance checks

---

## Tools

- **SQL** (PostgreSQL-compatible syntax)
- **Dataset:** CSV — enterprise data center energy portfolio, full year 2024

---

## About

Built as part of the **Google Data Analytics Professional Certificate** capstone and independent analytical work through **Flying Gem Consulting LLC**.

*Gemaron | Operations Manager | Data Analyst | U.S. Coast Guard Veteran*
[LinkedIn](https://www.linkedin.com/in/gcwillis) | [Many Rivers on Substack](https://manyrivers.substack.com)


