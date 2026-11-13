import pandas as pd
import re

RAW = "data/raw/wfp_food_prices_ken.csv"   
OUT = "data/clean/kenya_food_prices_clean.csv"

df = pd.read_csv(RAW)

# 1. Basic look
print(df.shape)
print(df.dtypes)
print(df.isna().sum())
print(df["pricetype"].value_counts())
print(df["priceflag"].value_counts())
print(df["unit"].value_counts())

# 2. Fix types
df["date"] = pd.to_datetime(df["date"], errors="coerce")
df["price"] = pd.to_numeric(df["price"], errors="coerce")
df["usdprice"] = pd.to_numeric(df["usdprice"], errors="coerce")
df = df.dropna(subset=["date", "price"])

# 3. Add date parts (needed for seasonality later)
df["year"] = df["date"].dt.year
df["month"] = df["date"].dt.month

# 4. Standardise units -> price per KG (or per L for liquids)
def parse_unit(u):
    u = str(u).strip().upper()
    m = re.match(r"^(\d+(?:\.\d+)?)?\s*(KG|G|L|ML)$", u)
    if not m:
        return (None, None)
    qty = float(m.group(1)) if m.group(1) else 1.0
    unit = m.group(2)
    if unit == "G":
        return (qty / 1000, "KG")
    if unit == "ML":
        return (qty / 1000, "L")
    return (qty, unit)

parsed = df["unit"].apply(parse_unit)
df["unit_qty"] = parsed.apply(lambda x: x[0])
df["base_unit"] = parsed.apply(lambda x: x[1])

# keep only rows whose unit we could standardise
unparsed = df[df["unit_qty"].isna()]["unit"].value_counts()
print("Units we couldn't parse:\n", unparsed)

df = df.dropna(subset=["unit_qty"])
df["price_per_unit"] = df["price"] / df["unit_qty"]
df["usd_price_per_unit"] = df["usdprice"] / df["unit_qty"]

# 5. Drop exact duplicates, tidy text
df = df.drop_duplicates()
for col in ["admin1", "admin2", "market", "category", "commodity"]:
    df[col] = df[col].str.strip()

# 6. Save
df.to_csv(OUT, index=False)
print("Saved", df.shape, "rows to", OUT)