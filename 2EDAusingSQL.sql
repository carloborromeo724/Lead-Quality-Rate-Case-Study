-- 
-- RZR Analytics Challenge — Step 2: Exploratory Data Analysis (SQL)
-- Database: rzr_case_study, Table: leads (3,021 rows)
-- "Lead quality rate" = closed leads / all leads sold (matches the
-- 8.0% baseline the advertiser quoted: 245/3021 = 8.11%)

-- 0. Starting point: reproduce the 8.0% baseline quality rate

SELECT
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2)  AS quality_rate_pct
FROM leads;
-- Here, I reproduced the 8.11% quality rate.


-- Q1. LEAD QUALITY TRENDS OVER TIME

SELECT
    lead_created_month,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY lead_created_month
ORDER BY lead_created_month;
-- Found out that the month of April (2009-04) has the highest quality rate as opposed to the month of
-- September (2009-09), which has the lowest quality rate. It is recommended to look deeper into the 
-- changes made in the company during this period.

-- Full lead-quality-bucket breakdown by month (not just Closed) for context
SELECT
    lead_created_month,
    lead_quality_bucket,
    COUNT(*) AS n
FROM leads
GROUP BY lead_created_month, lead_quality_bucket
ORDER BY lead_created_month, lead_quality_bucket;

-- Found out that the lead quality "Unknown - No Outcome Recorded" dominates each month.
-- 
-- Q2. DRIVERS OF LEAD QUALITY 
-- (Statistical significance was tested in Python/scipy — chi-square
--  per segment.)
-- 

-- 2a. By ad creative (WidgetName) (only significant with enough volume per group)
SELECT
    widget_name,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY widget_name
HAVING COUNT(*) >= 20 -- drop tiny groups and unreliable %
ORDER BY quality_rate_pct DESC;

-- 2b. By page placement (PublisherZoneName)
SELECT
    publisher_zone_name,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY publisher_zone_name
ORDER BY quality_rate_pct DESC;

-- Found that Top Right-300x250 has a higer quality rate (9.59%) than TopLeft-302252 (7.96)
-- 2c. By intake channel - online form vs. call center (PublisherCampaignName)
SELECT
    publisher_campaign_name,
    COUNT(*)                                  AS total_leads,
    SUM(is_closed)                            AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY publisher_campaign_name
ORDER BY quality_rate_pct DESC;

-- Found that Call Center as  the intake channel has a higher quality rate of 9.59%

-- 2d. By ad branding - branded vs. generic (AdvertiserCampaignName)
SELECT
    advertiser_campaign_name,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY advertiser_campaign_name
ORDER BY quality_rate_pct DESC;
-- Found out that Debt Settlement1 Master has a higher quality rate (8.32%)

-- 2e. By debt level (the strongest real driver found with p = 0.0062)
SELECT
    debt_level_raw,
    debt_level_midpoint,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY debt_level_raw, debt_level_midpoint
ORDER BY debt_level_midpoint;

-- The debt level with ranges 7500-10000 and more tahn 100000 have the lowest quality rate 
-- of 4.98% and 3.66, respectively.

-- 2f. By state (top 10 by volume, to avoid noisy tiny-sample states)
SELECT
    state,
    COUNT(*)                                  AS total_leads,
    SUM(is_closed)                            AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY state
ORDER BY total_leads DESC
LIMIT 10;

-- 2g. By phone verification score (borderline significant with p = 0.0524)
SELECT
    phone_score,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
WHERE phone_score IS NOT NULL
GROUP BY phone_score
ORDER BY phone_score;

-- Majority of the entries have missing inputs for this column (around 1628 of the total leads)

-- 2h. By address verification score (not significant and only included for completeness)
SELECT
    address_score,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
WHERE address_score IS NOT NULL
GROUP BY address_score
ORDER BY address_score;

-- Majority of the entries have missing inputs for this column (around 1850 of the total leads)
-- ------------------------------------------------------------
-- Q3. WHERE'S THE OPPORTUNITY TO HIT 9.6%?
-- ------------------------------------------------------------

-- 3a. Debt-level segments that ALREADY beat the 9.6% target
SELECT
    debt_level_raw,
    COUNT(*) AS total_leads,
    SUM(is_closed) AS closed_leads,
    ROUND(SUM(is_closed) / COUNT(*) * 100, 2) AS quality_rate_pct
FROM leads
GROUP BY debt_level_raw
HAVING quality_rate_pct >= 9.6
ORDER BY quality_rate_pct DESC;

-- The debt level ranges that already beat the 9.6& target quality rate are 
-- 70001-90000 (13.74%), 10001-15000 (11.68%), and 90000-100000 (10.00%).

-- 3b. Simulation: what would overall quality rate be if we
--     dropped the worst debt segment (>$100,000, only 3.66% quality)?
SELECT
    ROUND(
        SUM(CASE WHEN debt_level_raw <> 'More_than_100000' THEN is_closed ELSE 0 END)
        / SUM(CASE WHEN debt_level_raw <> 'More_than_100000' THEN 1 ELSE 0 END) * 100
    , 2) AS quality_rate_excl_high_debt_pct,
    SUM(CASE WHEN debt_level_raw <> 'More_than_100000' THEN 1 ELSE 0 END) AS remaining_leads,
    (SELECT COUNT(*) FROM leads WHERE debt_level_raw = 'More_than_100000') AS leads_removed
FROM leads;

-- By dropping the debt level of more than 100000, 191 of the leads are removed and the quality rate improved (8.41%)
