DROP TABLE IF EXISTS `walmart_sales`;
CREATE TABLE `walmart_sales` (
  `Invoice ID` VARCHAR(64),
  `Branch` VARCHAR(32),
  `City` VARCHAR(64),
  `Customer type` VARCHAR(32),
  `Gender` VARCHAR(16),
  `Product line` VARCHAR(64),
  `Unit price` DECIMAL(12,2),
  `Quantity` INT,
  `Tax 5%` DECIMAL(12,2),
  `Total` DECIMAL(14,2),
  `Date` DATE,
  `Time` TIME,
  `Payment` VARCHAR(32),
  `cogs` DECIMAL(14,2),
  `gross margin percentage` DECIMAL(6,3),
  `gross income` DECIMAL(14,2),
  `Rating` DECIMAL(3,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


LOAD DATA LOCAL INFILE '/path/to/Walmart Sales Data.csv.csv'
INTO TABLE `walmart_sales`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`Invoice ID`, `Branch`, `City`, `Customer type`, `Gender`, `Product line`,
 `Unit price`, `Quantity`, `Tax 5%`, `Total`, `Date`, `Time`, `Payment`,
 `cogs`, `gross margin percentage`, `gross income`, `Rating`);

-- -------------------------
-- 1) Single-row KPI summary
-- -------------------------
SELECT
  COUNT(DISTINCT `Invoice ID`)                     AS total_transactions,
  SUM(`Total`)                                     AS total_revenue,
  SUM(`Quantity`)                                  AS total_units_sold,
  AVG(`Total`)                                     AS avg_transaction_value,
  SUM(`gross income`)                              AS total_gross_income,
  CASE WHEN SUM(`Total`) = 0 THEN 0
       ELSE ROUND(100 * SUM(`gross income`) / SUM(`Total`), 4) END
                                                   AS effective_gross_margin_pct,
  AVG(`Rating`)                                    AS avg_rating
FROM `walmart_sales`;

-- -------------------------
-- 2) Revenue & Units by Branch
-- -------------------------
SELECT
  `Branch`,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units_sold,
  AVG(`Total`)                                     AS avg_transaction_value
FROM `walmart_sales`
GROUP BY `Branch`
ORDER BY revenue DESC;

-- -------------------------
-- 3) Top Product Lines by Revenue (Top N)
-- -------------------------
SELECT
  `Product line`,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Quantity`)                                  AS units_sold,
  SUM(`Total`)                                     AS revenue,
  AVG(`Rating`)                                    AS avg_rating
FROM `walmart_sales`
GROUP BY `Product line`
ORDER BY revenue DESC
LIMIT 10;

-- -------------------------
-- 4) Payment Method Distribution
-- -------------------------
SELECT
  `Payment`,
  COUNT(*)                                         AS tx_count,
  SUM(`Total`)                                     AS revenue,
  ROUND(100 * SUM(`Total`) / NULLIF((SELECT SUM(`Total`) FROM `walmart_sales`),0), 2) AS revenue_pct
FROM `walmart_sales`
GROUP BY `Payment`
ORDER BY revenue DESC;

-- -------------------------
-- 5) Revenue by Customer Type (Member vs Normal)
-- -------------------------
SELECT
  `Customer type`,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units_sold,
  AVG(`Total`)                                     AS avg_transaction_value
FROM `walmart_sales`
GROUP BY `Customer type`
ORDER BY revenue DESC;

-- -------------------------
-- 6) Gender-based Sales Contribution
-- -------------------------
SELECT
  `Gender`,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units
FROM `walmart_sales`
GROUP BY `Gender`
ORDER BY revenue DESC;

-- -------------------------
-- 7) Gross Profit Analysis
-- -------------------------
SELECT
  SUM(`gross income`)                              AS total_gross_income,
  AVG(`gross margin percentage`)                   AS avg_gross_margin_percentage,
  CASE WHEN SUM(`Total`) = 0 THEN 0
       ELSE ROUND(100 * SUM(`gross income`) / SUM(`Total`), 4) END
                                                   AS effective_gross_margin_pct
FROM `walmart_sales`;

-- -------------------------
-- 8) Customer Ratings Insights
-- -------------------------
-- Frequency & average invoice total by rating
SELECT
  `Rating`,
  COUNT(*)                                         AS cnt,
  ROUND(AVG(`Total`),2)                            AS avg_total
FROM `walmart_sales`
GROUP BY `Rating`
ORDER BY `Rating` DESC;

--  rating buckets
SELECT
  CASE
    WHEN `Rating` <= 2 THEN '1-2'
    WHEN `Rating` > 2 AND `Rating` < 4 THEN '2.1-3.9'
    WHEN `Rating` >= 4 AND `Rating` < 4.5 THEN '4-4.4'
    WHEN `Rating` >= 4.5 THEN '4.5-5'
    ELSE 'unknown'
  END AS rating_bucket,
  COUNT(*)                                         AS cnt,
  SUM(`Total`)                                     AS revenue,
  ROUND(AVG(`Total`),2)                            AS avg_total
FROM `walmart_sales`
GROUP BY rating_bucket
ORDER BY revenue DESC;

-- -------------------------
-- 9) Trend Analysis: Daily / Monthly / Weekly revenue
-- -------------------------
-- Daily revenue trend
SELECT
  `Date`                                           AS day,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units_sold
FROM `walmart_sales`
GROUP BY `Date`
ORDER BY `Date`;

-- Monthly revenue trend (first day of month shown)
SELECT
  DATE_FORMAT(`Date`, '%Y-%m-01')                  AS month,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units_sold
FROM `walmart_sales`
GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY month;

-- Weekly revenue trend (week start = Monday)
SELECT
  DATE_SUB(`Date`, INTERVAL WEEKDAY(`Date`) DAY)   AS week_start,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue
FROM `walmart_sales`
GROUP BY week_start
ORDER BY week_start;

-- -------------------------
-- 10) Month-over-Month (MoM) revenue growth
-- -------------------------
WITH monthly AS (
  SELECT
    DATE_FORMAT(`Date`, '%Y-%m-01')                AS month_start,
    SUM(`Total`)                                   AS revenue
  FROM `walmart_sales`
  GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
)
SELECT
  month_start,
  revenue,
  revenue - LAG(revenue) OVER (ORDER BY month_start) AS revenue_change,
  CASE WHEN LAG(revenue) OVER (ORDER BY month_start) IS NULL THEN NULL
       WHEN LAG(revenue) OVER (ORDER BY month_start) = 0 THEN NULL
       ELSE ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month_start)) / LAG(revenue) OVER (ORDER BY month_start), 2)
  END AS pct_change
FROM monthly
ORDER BY month_start;

-- -------------------------
-- 11) Branch-level monthly trends
-- -------------------------
SELECT
  `Branch`,
  DATE_FORMAT(`Date`, '%Y-%m-01')                  AS month,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units_sold
FROM `walmart_sales`
GROUP BY `Branch`, DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY `Branch`, month;

-- -------------------------
-- 12) Hourly sales pattern (time-of-day)
-- -------------------------

SELECT
  CAST(CONCAT(`Date`, ' ', `Time`) AS DATETIME)    AS dt,
  DATE_FORMAT(CAST(CONCAT(`Date`, ' ', `Time`) AS DATETIME), '%Y-%m-%d %H:00:00') AS hour_bucket,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units_sold
FROM `walmart_sales`
GROUP BY hour_bucket
ORDER BY hour_bucket;

-- -------------------------
-- 13) Basket metrics
-- -------------------------
SELECT
  ROUND(SUM(`Quantity`) / NULLIF(COUNT(DISTINCT `Invoice ID`),0), 4) AS avg_items_per_transaction,
  ROUND(AVG(`Unit price`),2)                                         AS avg_unit_price,
  ROUND(AVG(`Total` / NULLIF(`Quantity`,0)),2)                      AS avg_price_per_item_in_txn
FROM `walmart_sales`;

-- -------------------------
-- 14) Top transactions by value (top 20 invoices)
-- -------------------------
SELECT
  `Invoice ID`,
  `Date`,
  SUM(`Total`) AS invoice_total,
  SUM(`Quantity`) AS items
FROM `walmart_sales`
GROUP BY `Invoice ID`, `Date`
ORDER BY invoice_total DESC
LIMIT 20;

-- -------------------------
-- 15) filter: revenue for Branch = 'A' in Jan 2019
-- -------------------------
SELECT
  SUM(`Total`)                                     AS revenue
FROM `walmart_sales`
WHERE `Branch` = 'A'
  AND DATE_FORMAT(`Date`, '%Y-%m') = '2019-01';

-- -------------------------
-- 16) Views for easy BI integration
-- -------------------------
DROP VIEW IF EXISTS `view_kpi_overview`;
CREATE VIEW `view_kpi_overview` AS
SELECT
  COUNT(DISTINCT `Invoice ID`)                     AS total_transactions,
  SUM(`Total`)                                     AS total_revenue,
  SUM(`Quantity`)                                  AS total_units_sold,
  AVG(`Total`)                                     AS avg_transaction_value,
  SUM(`gross income`)                              AS total_gross_income,
  AVG(`Rating`)                                    AS avg_rating
FROM `walmart_sales`;

DROP VIEW IF EXISTS `view_monthly_revenue`;
CREATE VIEW `view_monthly_revenue` AS
SELECT
  DATE_FORMAT(`Date`, '%Y-%m-01')                  AS month,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Total`)                                     AS revenue,
  SUM(`Quantity`)                                  AS units_sold
FROM `walmart_sales`
GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY month;

DROP VIEW IF EXISTS `view_top_product_lines`;
CREATE VIEW `view_top_product_lines` AS
SELECT
  `Product line`,
  COUNT(DISTINCT `Invoice ID`)                     AS transactions,
  SUM(`Quantity`)                                  AS units_sold,
  SUM(`Total`)                                     AS revenue,
  AVG(`Rating`)                                    AS avg_rating
FROM `walmart_sales`
GROUP BY `Product line`
ORDER BY revenue DESC;

-- -------------------------
-- 17) Index suggestions
-- -------------------------
CREATE INDEX IF NOT EXISTS idx_walmart_date ON `walmart_sales` (`Date`);
CREATE INDEX IF NOT EXISTS idx_walmart_branch ON `walmart_sales` (`Branch`);
CREATE INDEX IF NOT EXISTS idx_walmart_product_line ON `walmart_sales` (`Product line`);


