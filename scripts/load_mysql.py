import os
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

password = os.environ["MYSQL_PASSWORD"]

url = URL.create(
    drivername="mysql+pymysql",
    username="root",
    password=password,
    host="localhost",
    database="kenya_food_prices",
)
engine = create_engine(url)

df = pd.read_csv("data/clean/kenya_food_prices_clean.csv", parse_dates=["date"])
df = df.rename(columns={"date": "price_date"})

df.to_sql("food_prices", engine, if_exists="append", index=False, chunksize=2000)
print("Loaded", len(df), "rows")