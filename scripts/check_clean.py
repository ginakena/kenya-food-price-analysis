import pandas as pd

df = pd.read_csv("data/clean/kenya_food_prices_clean.csv", parse_dates=["date"])
raw = pd.read_csv("data/raw/wfp_food_prices_ken.csv") 

# 1. Date range and coverage
print("Date range:", df["date"].min(), "to", df["date"].max())
print("Markets:", df["market"].nunique(), "| Commodities:", df["commodity"].nunique())

# 2. What are the 68 rows with no admin1?
print("\nRows with missing admin1:")
print(df[df["admin1"].isna()]["market"].value_counts())

# 3. What did we drop?
dropped = raw[raw["unit"].isin(["Unit", "Head", "Bunch"])]
print("\nDropped rows by commodity:")
print(dropped["commodity"].value_counts())

# 4. Maize price per KG should be roughly 20-100 KES
maize = df[df["commodity"].str.contains("Maize", case=False)]
print("\nMaize price per KG by price type:")
print(maize.groupby("pricetype")["price_per_unit"].describe())

# 5. Anything suspiciously high or low overall?
print("\nHighest price_per_unit rows:")
print(df.nlargest(5, "price_per_unit")[["date", "market", "commodity", "unit", "price", "price_per_unit"]])