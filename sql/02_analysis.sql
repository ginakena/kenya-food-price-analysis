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

-- 3. Volatility (month-to-month change within each market, consecutive months only)
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
       ROUND(STDDEV(pct_change) * 100, 1) AS volatility_pct,
       COUNT(*) AS obs,
       COUNT(DISTINCT market_id) AS markets
FROM changes
WHERE gap_months = 1
GROUP BY commodity
HAVING COUNT(*) >= 200
ORDER BY volatility_pct DESC;

-- 4. Regional price gap: white maize, retail, 2025
SELECT admin1, ROUND(AVG(price_per_unit), 1) AS avg_kes_per_kg, COUNT(*) AS n
FROM food_prices
WHERE commodity = 'Maize (white)' AND pricetype = 'Retail'
  AND base_unit = 'KG' AND year = 2025
GROUP BY admin1
ORDER BY avg_kes_per_kg DESC;