CREATE DATABASE IF NOT EXISTS kenya_food_prices;
USE kenya_food_prices;

CREATE TABLE IF NOT EXISTS food_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    price_date DATE NOT NULL,
    admin1 VARCHAR(50),
    admin2 VARCHAR(50),
    market VARCHAR(100) NOT NULL,
    market_id INT,
    latitude DECIMAL(8,4),
    longitude DECIMAL(8,4),
    category VARCHAR(50),
    commodity VARCHAR(80) NOT NULL,
    commodity_id INT,
    unit VARCHAR(20),
    priceflag VARCHAR(30),
    pricetype VARCHAR(20),
    currency VARCHAR(5),
    price DECIMAL(12,2),
    usdprice DECIMAL(12,4),
    year SMALLINT,
    month TINYINT,
    unit_qty DECIMAL(10,3),
    base_unit VARCHAR(5),
    price_per_unit DECIMAL(12,4),
    usd_price_per_unit DECIMAL(12,4),
    INDEX idx_commodity (commodity),
    INDEX idx_market (market),
    INDEX idx_date (price_date)
);