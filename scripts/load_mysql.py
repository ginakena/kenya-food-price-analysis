import os
import pandas as pd
from sqlalchemy import create_engine

# Set this in your terminal first:  set MYSQL_PASSWORD=yourpassword
password = os.environ["MYSQL_PASSWORD"]
engine = create_engine(f"mysql+pymysql://root:{password}@localhost/kenya_food_prices")

df = pd.read_csv("data/clean/kenya_food_prices_clean.csv", parse_dates=["date"])
df = df.rename(columns={"date": "price_date"})

df.to_sql("food_prices", engine, if_exists="append", index=False, chunksize=2000)
print("Loaded", len(df), "rows")