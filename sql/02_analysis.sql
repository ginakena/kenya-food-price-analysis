USE kenya_food_prices;

-- 1. Sanity checks
SELECT pricetype, COUNT(*) AS n FROM food_prices GROUP BY pricetype;
SELECT MIN(price_date), MAX(price_date), COUNT(DISTINCT market), COUNT(DISTINCT commodity) FROM food_prices;

-- 2. Seasonality: is a commodity pricier or cheaper than usual in a given month?
-- Index of 1.10 means 10% above that year's average. Dividing by each year's own
-- average removes the long-run price rise (inflation) so months can be compared.
WITH monthly AS (
    SELECT commodity, year, month, AVG(price_per_unit) AS avg_price
    FROM food_prices
    WHERE pricetype = 'Retail' AND base_unit = 'KG' AND year BETWEEN 2010 AND 2025
    GROUP BY commodity, year, month
),
yearly AS (
    SELECT commodity, year, AVG(avg_price) AS yr_avg
    FROM monthly
    GROUP BY commodity, year
)
SELECT m.commodity, m.month,
       ROUND(AVG(m.avg_price / y.yr_avg), 3) AS seasonal_index
FROM monthly m
JOIN yearly y ON m.commodity = y.commodity AND m.year = y.year
GROUP BY m.commodity, m.month
ORDER BY m.commodity, m.month;

-- 3. Volatility: how much does the national average retail price jump month to month?
SELECT commodity,
       ROUND(STDDEV(pct_change) * 100, 1) AS volatility_pct,
       COUNT(*) AS months
FROM (
    SELECT commodity, price_date,
           avg_price / LAG(avg_price) OVER (PARTITION BY commodity ORDER BY price_date) - 1 AS pct_change
    FROM (
        SELECT commodity, price_date, AVG(price_per_unit) AS avg_price
        FROM food_prices
        WHERE pricetype = 'Retail' AND base_unit = 'KG'
        GROUP BY commodity, price_date
    ) m
) c
WHERE pct_change IS NOT NULL
GROUP BY commodity
HAVING COUNT(*) >= 60
ORDER BY volatility_pct DESC;

-- 4. Regional price gap: white maize, retail, 2025
SELECT admin1, ROUND(AVG(price_per_unit), 1) AS avg_kes_per_kg, COUNT(*) AS n
FROM food_prices
WHERE commodity = 'Maize (white)' AND pricetype = 'Retail'
  AND base_unit = 'KG' AND year = 2025
GROUP BY admin1
ORDER BY avg_kes_per_kg DESC;