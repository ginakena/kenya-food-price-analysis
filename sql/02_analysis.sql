USE kenya_food_prices;

-- 1. Sanity checks
SELECT pricetype, COUNT(*) AS n FROM food_prices GROUP BY pricetype;
SELECT MIN(price_date), MAX(price_date), COUNT(DISTINCT market), COUNT(DISTINCT commodity) FROM food_prices;

-- 2. Seasonality (each market compared with its own annual average)
WITH monthly AS (
    SELECT commodity, market_id, year, month, AVG(price_per_unit) AS avg_price
    FROM food_prices
    WHERE pricetype = 'Retail' AND base_unit = 'KG' AND year BETWEEN 2010 AND 2025
    GROUP BY commodity, market_id, year, month
),
yearly AS (
    SELECT commodity, market_id, year, AVG(avg_price) AS yr_avg
    FROM monthly
    GROUP BY commodity, market_id, year
    HAVING COUNT(*) >= 6          -- only market-years with at least 6 months observed
)
SELECT m.commodity, m.month,
       ROUND(AVG(m.avg_price / y.yr_avg), 3) AS seasonal_index,
       COUNT(DISTINCT m.year) AS years_observed,
       COUNT(DISTINCT m.market_id) AS markets
FROM monthly m
JOIN yearly y ON m.commodity = y.commodity AND m.market_id = y.market_id AND m.year = y.year
GROUP BY m.commodity, m.month
HAVING COUNT(DISTINCT m.year) >= 5 AND COUNT(DISTINCT m.market_id) >= 3
ORDER BY m.commodity, m.month;


-- 3. Volatility robustness: all changes vs excluding jumps of 100% or more
WITH monthly AS (
    SELECT commodity, market_id, price_date, AVG(price_per_unit) AS avg_price
    FROM food_prices
    WHERE pricetype = 'Retail' AND base_unit = 'KG'
    GROUP BY commodity, market_id, price_date
),
changes AS (
    SELECT commodity, market_id,
           avg_price / LAG(avg_price) OVER w - 1 AS pct_change,
           TIMESTAMPDIFF(MONTH, LAG(price_date) OVER w, price_date) AS gap_months
    FROM monthly
    WINDOW w AS (PARTITION BY commodity, market_id ORDER BY price_date)
)
SELECT commodity,
       ROUND(STDDEV(pct_change) * 100, 1) AS volatility_all,
       ROUND(STDDEV(CASE WHEN ABS(pct_change) < 1 THEN pct_change END) * 100, 1) AS volatility_trimmed,
       SUM(ABS(pct_change) >= 1) AS jumps_100pct_plus,
       COUNT(*) AS obs
FROM changes
WHERE gap_months = 1
GROUP BY commodity
HAVING COUNT(*) >= 200
ORDER BY volatility_trimmed DESC;

-- 4. Maize seasonality across the full series, split into two eras
WITH maize AS (
    SELECT market_id, year, month, price_per_unit
    FROM food_prices
    WHERE pricetype = 'Retail' AND base_unit = 'KG'
      AND commodity IN ('Maize (white)', 'Maize')
),
monthly AS (
    SELECT market_id, year, month, AVG(price_per_unit) AS avg_price
    FROM maize
    GROUP BY market_id, year, month
),
yearly AS (
    SELECT market_id, year, AVG(avg_price) AS yr_avg
    FROM monthly
    GROUP BY market_id, year
    HAVING COUNT(*) >= 6
)
SELECT CASE WHEN m.year <= 2015 THEN '2006-2015' ELSE '2016-2026' END AS era,
       m.month,
       ROUND(AVG(m.avg_price / y.yr_avg), 3) AS seasonal_index,
       COUNT(DISTINCT m.market_id) AS markets,
       COUNT(DISTINCT m.year) AS years
FROM monthly m
JOIN yearly y ON m.market_id = y.market_id AND m.year = y.year
GROUP BY era, m.month
HAVING COUNT(DISTINCT m.market_id) >= 3
ORDER BY era, m.month;

--  Which maize series cover which regions? (2024-2026, retail, per KG)
SELECT commodity, admin1, COUNT(DISTINCT market_id) AS markets, COUNT(*) AS n
FROM food_prices
WHERE commodity LIKE 'Maize%' AND commodity NOT LIKE 'Maize flour%'
  AND pricetype = 'Retail' AND base_unit = 'KG' AND year BETWEEN 2024 AND 2026
GROUP BY commodity, admin1
ORDER BY admin1, commodity;

--  Regional gap, averaging each market first so busy markets don't dominate
SELECT admin1, ROUND(AVG(market_avg), 1) AS avg_kes_per_kg, COUNT(*) AS markets
FROM (
    SELECT admin1, market_id, AVG(price_per_unit) AS market_avg
    FROM food_prices
    WHERE commodity IN ('Maize', 'Maize (white, dry)')
      AND pricetype = 'Retail' AND base_unit = 'KG' AND year BETWEEN 2024 AND 2026
    GROUP BY admin1, market_id
) m
GROUP BY admin1
HAVING COUNT(*) >= 3
ORDER BY avg_kes_per_kg DESC;

--  Regional maize price by year (are regions comparable within each year?)
SELECT admin1, year, ROUND(AVG(price_per_unit), 1) AS avg_kes_per_kg,
       COUNT(DISTINCT market_id) AS markets
FROM food_prices
WHERE commodity IN ('Maize', 'Maize (white, dry)')
  AND pricetype = 'Retail' AND base_unit = 'KG' AND year BETWEEN 2024 AND 2026
GROUP BY admin1, year
ORDER BY year, avg_kes_per_kg DESC;