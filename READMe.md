# Kenya Food Price Trends & Seasonality

An analysis of WFP market price data for Kenya: which foods have the most volatile prices, whether prices follow a seasonal pattern, and how maize prices differ across regions.

**Tools:** Python (Pandas), MySQL, Power BI
**Data source:** [WFP Food Prices for Kenya](https://data.humdata.org/dataset/wfp-food-prices-for-kenya), via the Humanitarian Data Exchange (HDX)
**Status:** Cleaning, loading and SQL analysis complete. Power BI dashboard in progress.

---

## Key findings

All figures use **retail prices per KG** only, so they are like-for-like. Wholesale prices and items that cannot be converted to weight are excluded (see [Data cleaning](#data-cleaning)).

### 1. Price volatility

Month-to-month price swings were largest for sorghum and Irish potatoes, and smallest for wheat flour, sugar and maize flour. Volatility is the standard deviation of month-to-month price change within each market, measured on consecutive months only. The figures below exclude month-to-month jumps of 100% or more, which are likely data errors or unit slips.

| Commodity | Volatility (all changes) | Volatility (jumps of 100%+ excluded) | Jumps removed |
|---|---|---|---|
| Sorghum | 29.1% | **19.4%** | 5 |
| Potatoes (Irish) | 21.5% | **18.6%** | 3 |
| Maize | 15.6% | 14.4% | 2 |
| Rice | 13.5% | 13.5% | 0 |
| Beans (dry) | 10.8% | 10.8% | 0 |
| Maize (white) | 10.9% | 9.9% | 1 |
| Meat (beef) | 8.5% | 8.5% | 0 |
| Meat (goat) | 8.4% | 8.4% | 0 |
| Sugar | 8.1% | 8.1% | 0 |
| Maize flour | 7.7% | 7.7% | 0 |
| Wheat flour | 7.9% | 6.7% | 1 |

- Sorghum and Irish potatoes only have meaningful history from 2021 (earlier years have one record per year), so their results describe roughly 2021 to 2026. Maize (white), beans and bread have much longer histories, so the windows differ across commodities.
- **Salt is left out of the headline results.** Its volatility fell from 27% to 14.5% once extreme jumps were removed, and it is a cheap item with coarse price steps, so small changes look large in percentage terms.

### 2. Seasonality

Maize and dry beans show only mild seasonality, and there is no strong evidence of a fixed seasonal cycle.

- **Method:** each market's monthly average price is divided by that market's own average for the year, so long-run price rises do not distort the comparison. An index of 1.05 means 5% above that year's average.
- **Dry beans (2010 to 2025):** index ranges from 0.958 (January) to 1.045 (June), a swing of about 9 points.
- **Maize (2016 to 2026):** index stays between about 0.98 and 1.03, with the highest values in May to August.
- **Not stable over time:** in 2006 to 2015 maize was cheapest in February to April and dearest in November and December. In 2016 to 2026 it was cheapest in January and February and dearest in May to August. Only July (about 1.027 in both periods) and the January-February low are consistent. The earlier period has only 9 markets.

### 3. Regional maize prices

Pooled regional averages turned out to be unreliable, so regions are compared **within each year**.

| Region | 2024 | 2025 | 2026 (to Oct) |
|---|---|---|---|
| Rift Valley | 73.6 (75 markets) | 68.3 (23) | 60.6 (20) |
| Eastern | 74.8 (32) | 87.9 (6) | 78.3 (15) |
| Coast | 77.0 (15) | 80.2 (9) | 79.3 (13) |
| North Eastern | 87.5 (26) | 76.3 (16) | 82.0 (21) |

*Average retail price, KES per KG, with the number of reporting markets in brackets.*

- **Rift Valley had the lowest average maize price in each of 2024, 2025 and 2026**, though the gap in 2024 was small (about 1 KES/KG versus Eastern).
- An earlier pooled comparison suggested North Eastern was about 26% more expensive. This did not hold up: North Eastern ranks third in 2025, and the number of reporting markets per region changes sharply between years (for example Eastern goes from 32 markets in 2024 to 6 in 2025).
- 2026 is a partial year.

---

## Data cleaning

Raw file: 29,298 rows, 16 columns, covering 227 markets and 50 commodities from January 2006 to October 2026.

| Issue | What I did |
|---|---|
| Prices quoted in mixed units (KG, 13/50/64/90/126 KG bags, 200 G, 400 G, L, 500 ML) | Parsed each unit and converted every price to price **per KG or per litre** |
| Items priced per `Unit`, `Head` or `Bunch` (Bananas 608 rows, Cabbage 26, Kale 22) | Excluded 656 rows. No reliable way to convert to weight, and assuming an average weight would hide a guess inside the results |
| 68 rows missing region and coordinates | All were one market (Hola, Tana River). Filled `admin1` as Coast and `admin2` as Tana River instead of deleting the rows |
| Implausible kale price (900 KES/KG) | Removed kale records above 300 KES/KG after checking against the commodity's usual range |
| Wholesale and retail mixed in one file | Kept `pricetype`, never averaged the two together. Analysis uses retail only |
| Dates as text | Parsed to dates, added `year` and `month` columns |

**Result:** 28,640 rows loaded into MySQL (19,239 retail and 9,401 wholesale).

## SQL analysis

All analysis queries are in [`sql/02_analysis.sql`](sql/02_analysis.sql). Notable design choices:

- **Compare each market against itself.** The set of markets reporting changes from month to month, so a simple national average can jump without any price changing. Seasonality and volatility are both calculated within each market.
- **Minimum coverage filters.** Seasonality requires at least 5 years, 3 markets and 6 observed months per market-year. Volatility requires at least 200 observations. This drops sparse series (for example onions, tomatoes and quarterly-only commodities) that gave misleading results in a first pass.
- **Maize treated as one series.** `Maize (white)` (2006 to 2020) and `Maize` (2020 to 2026) are combined for seasonality. For recent regional comparisons, `Maize` and `Maize (white, dry)` (2023 to 2026) are combined. Dry white maize may price slightly differently, so this is a judgement call.
- **Robustness checks.** Volatility is reported with and without extreme jumps, and the regional result was re-tested year by year (which is what overturned the first regional finding).

## Limitations

- Retail, per-KG items only. Bananas, cabbage and kale priced per piece, head or bunch are not covered.
- Reporting markets change over time, so national averages and pooled regional averages should be read with care.
- Sorghum and potatoes have a short usable history (about 2021 onward).
- Maize seasonality differs between periods, so the seasonal patterns are weak evidence, not a forecast.
- 2026 data runs to October only.
- Several price records are flagged `aggregate` in the source data. They are retained, and `priceflag` is kept in the dataset for filtering.
- These results describe prices in the WFP-monitored markets, which may not represent all of Kenya.

## Repository structure

```
kenya-food-price-analysis/
├── data/
│   ├── raw/          # original WFP file, untouched
│   └── clean/        # cleaned output of clean_data.py
├── scripts/
│   ├── clean_data.py       # cleaning and unit standardisation
│   ├── check_clean.py      # validation checks on the cleaned data
│   └── load_mysql.py       # loads cleaned data into MySQL
├── sql/
│   ├── 01_schema.sql       # database and table definition
│   └── 02_analysis.sql     # seasonality, volatility and regional queries
├── dashboard/        # Power BI report 
└── notebooks/
```

## How to reproduce

1. Download the Kenya food prices CSV from the HDX link above and save it as `data/raw/wfp_food_prices_ken.csv`.
2. Install dependencies: `pip install pandas sqlalchemy pymysql`
3. Clean the data: `python scripts/clean_data.py`
4. Validate the output: `python scripts/check_clean.py`
5. Create the database in MySQL: `SOURCE sql/01_schema.sql;`
6. Set the database password as an environment variable (it is never stored in the repo), then load the data:
   ```
   set MYSQL_PASSWORD=your_password
   python scripts/load_mysql.py
   ```
7. Run the analysis: `mysql -u root -p < sql/02_analysis.sql`

## Next steps

- Power BI dashboard: price trends by commodity, volatility ranking, and regional maize view, with commodity, region and year filters.

## Author

Gee ([@ginakena](https://github.com/ginakena))
