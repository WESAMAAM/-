# Contoso Retail Analytics and Business Intelligence with PostgreSQL

## Table of Contents

* [Project Overview](#project-overview)
* [Dataset and Schema Architecture](#dataset-and-schema-architecture)
* [Business Questions and SQL Solutions](#business-questions-and-sql-solutions)
* [Advanced SQL Queries and Statistical Analysis](#advanced-sql-queries-and-statistical-analysis)
* [Database Views and Semantic Modeling](#database-views-and-semantic-modeling)
* [Comprehensive Business Analysis and Findings](#comprehensive-business-analysis-and-findings)
* [Tools and Technologies](#tools-and-technologies)

## Project Overview

This project represents the practical culmination and hands on portfolio application of everything learned in the comprehensive video course SQL for Data Analytics Intermediate Course plus Project taught by Luke Barousse. Through this course, theoretical SQL concepts were transformed into practical data engineering and analytical problem solving skills applied to a real business scenario.

The learning journey documented in this project reflects a complete progression from foundational querying to advanced commercial analysis using the Microsoft Contoso retail dataset. Rather than simply writing basic queries, the training focused on understanding the deeper business context, solving executive problems, and extracting meaningful intelligence across ten years of operational history.

![01 sales table exploration](images/Screenshot%202026-10-09%20170625.png)

## Dataset and Schema Architecture

The dataset used in this project is the standardized Microsoft Contoso 100k database. It follows a star schema design where a large fact table connects to descriptive dimension tables.

Core tables:
* `sales`: The central fact table storing transaction line items, order dates, delivery dates, quantities, prices, and exchange rates.
* `customer`: Dimension table containing customer identity, full country names, gender, given names, surnames, and age.
* `product`: Dimension table containing product names, categories, and subcategories.
* `store`: Dimension table recording store locations.
* `currencyexchange`: Dimension table tracking currency conversion rates.

### Initial Data Inspection

The first step was inspecting the structure and columns of the central `sales` fact table:

```sql
SELECT *
FROM sales
LIMIT 10

````

![01 sales table exploration](images/01_sales_table_exploration.png)

This query confirmed that each row represents an individual line item within an order. The table includes both `orderdate` and `deliverydate`, as well as financial measures like `quantity`, `netprice`, and `exchangerate`. Because Contoso sells across multiple countries in currencies such as USD, CAD, and GBP, multiplying by `exchangerate` is required to normalize all revenue into US dollars.

### Data Exploration and Formatting

In PostgreSQL, the `TO_CHAR` function is used for numeric and date formatting instead of the `FORMAT` function found in SQL Server. Using the format pattern `FM999,999,999` ensures that numbers display with clean thousand separators without leading blank spaces.

The following query tests transaction categorization and joins the customer and product tables:


````sql
SELECT
  CASE WHEN sales.quantity * sales.netprice * sales.exchangerate >= 1000 THEN 'HIGH'
       ELSE 'LOW'
  END AS value,
  customer.givenname,
  customer.surname,
  product.productname,
  product.categoryname,
  product.subcategoryname,
  sales.orderdate,
  sales.productkey,
  sales.quantity,
  sales.quantity * sales.netprice * sales.exchangerate AS multiqne
FROM sales
LEFT JOIN customer USING (customerkey)
LEFT JOIN product USING (productkey)
WHERE orderdate::date >= '2020/01/01'

````

![02 transaction categorization](images/02_transaction_categorization.png)

To calculate total net revenue since the start of 2020, a Common Table Expression was implemented:


````sql
WITH nr AS
(
  SELECT
    quantity * netprice * exchangerate AS multiqne
  FROM sales
  WHERE orderdate::date >= '2020/01/01'
)

SELECT
  TO_CHAR(SUM(nr.multiqne), 'FM999,999,999') AS netrevenue
FROM nr

````

![03 total net revenue 2020](images/03_total_net_revenue_2020.png)

This calculation produced a total net revenue of 118946063 USD generated across 124451 transaction rows since January 1 2020.

## Business Questions and SQL Solutions

The core analysis answers three essential business questions.

### Question 1 Customer Segmentation Who Are Our Most Valuable Customers

To identify the highest value customers, two approaches were executed: a direct ranking query and an expanded persistent database view.

#### Grounded VIP Customer Ranking


````sql
SELECT DISTINCT
  c.customerkey,
  c.countryfull,
  c.givenname,
  c.surname,
  SUM(s.netprice * s.quantity * s.exchangerate) AS total_revenue
FROM sales s
LEFT JOIN customer c USING (customerkey)
GROUP BY c.customerkey
ORDER BY total_revenue DESC;

````

![04 top spenders ranking](images/04_top_spenders_ranking.png)

Top Individual Spenders:

1. Ben Davenport from Australia: 82057.67 USD
2. Peter Rodriguez from Canada: 79201.82 USD
3. Patricia Dalton from the United States: 65431.98 USD
4. James Thompson from the United States: 62460.01 USD
5. Robert Young from Canada: 61349.65 USD
6. Chelsea Pfeiffer from Canada: 60644.48 USD
7. Janina Unger from Germany: 56240.85 USD
8. David Green from the United States: 56073.21 USD
9. James McClendon from the United States: 55994.75 USD
10. Albert Kloss from the United States: 51550.86 USD

#### Expanded Customer Profile View

To combine demographic details, daily basket totals, order counts, and acquisition cohort years into a single layer, a database view was created:


````sql
CREATE VIEW cs_valubale_customers_info AS
WITH customer_data AS
(
  SELECT DISTINCT
    s.customerkey AS customerkey,
    s.orderdate AS orderdate,
    SUM(s.netprice * s.quantity * s.exchangerate) OVER(PARTITION BY s.customerkey,
                                                                    s.orderdate) AS total_net_revenue,
    COUNT(s.orderkey) OVER(PARTITION BY s.customerkey,
                                        s.orderdate) AS num_orders,
    MIN(s.orderdate) OVER(PARTITION BY s.customerkey) AS first_purchase_date,
    EXTRACT(YEAR FROM MIN(s.orderdate) OVER(PARTITION BY s.customerkey)) AS cohort_year,
    c.countryfull AS countryfull,
    c.age AS age,
    c.givenname AS name,
    c.surname AS surname
  FROM sales s
  LEFT JOIN customer c USING (customerkey)
)
SELECT
  d.customerkey,
  d.orderdate,
  TO_CHAR(d.total_net_revenue, 'FM999,999,999') AS total_net_revenue,
  d.num_orders,
  d.first_purchase_date,
  d.cohort_year,
  d.countryfull,
  d.age,
  d.name,
  d.surname
FROM customer_data d;

````

![05 create customer profile view](images/05_create_customer_profile_view.png)

Querying this view reveals detailed customer profiles:


````sql
SELECT *
FROM cs_valubale_customers_info

````

![06 view customer info output](images/06_view_customer_info_output.png)

For example customer Tahlia (key 688) from Australia joined in 2023 at age 28 and spent 16909 USD across five line items in a single transaction on September 13 2023.

### Question 2 Cohort Analysis How Do Different Groups Generate Revenue

Using the view `cs_valubale_customers_info`, revenue generation was calculated by cohort year:


````sql
SELECT
  cvci.cohort_year AS cohort_year,
  TO_CHAR(SUM(cvci.total_net_revenue), 'FM999,999,999') AS total_revenue,
  COUNT(DISTINCT cvci.customerkey) AS total_customers,
  PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY (cvci.total_net_revenue)) AS customer_revenue_per,
  AVG(cvci.total_net_revenue) AS customer_revenue_avg
FROM cs_valubale_customers_info cvci
GROUP BY cohort_year

````

![07 cohort revenue generation](images/07_cohort_revenue_generation.png)

Cohort Findings:

- 2015 Cohort: 2825 customers generated 14892230 USD.
- 2016 Cohort: 3397 customers generated 18360522 USD.
- 2017 Cohort: 4068 customers generated 21979734 USD.
- 2018 Cohort: 7446 customers generated 36460385 USD.
- 2019 Cohort: 7755 customers generated 36696244 USD.
- 2020 Cohort: 3031 customers generated 11921901 USD.
- 2021 Cohort: 4663 customers generated 18387736 USD.
- 2022 Cohort: 9010 customers generated 29872808 USD.
- 2023 Cohort: 5890 customers generated 14979328 USD.
- 2024 Cohort: 1402 customers generated 2856649 USD.

Median order spend stayed consistent between 1201 USD and 1379 USD across all cohorts. Differences in total revenue between years are driven primarily by acquisition volume and customer retention.

#### Multi Stage Cohort Lifetime Value Progression Pipeline

This query tracks the progression of customer lifetime value across cohorts using a three stage Common Table Expression:


````sql
WITH c_n AS
(
  SELECT
    customerkey,
    EXTRACT(YEAR FROM (MIN(orderdate))) AS cohort_year,
    SUM(netprice * quantity * exchangerate) AS customer_ltv
  FROM sales
  GROUP BY customerkey
),
cohort_summary AS
(
  SELECT
    cohort_year,
    customerkey,
    AVG(customer_ltv) OVER(PARTITION BY cohort_year) AS avg_cohort_ltv
  FROM c_n
  ORDER BY cohort_year
),
cohort_final AS
(
  SELECT DISTINCT
    cohort_year,
    avg_cohort_ltv
  FROM cohort_summary
  ORDER BY cohort_year
)
SELECT *,
  LAG(avg_cohort_ltv) OVER(ORDER BY cohort_year) AS p_ltv,
  avg_cohort_ltv - LAG(avg_cohort_ltv) OVER(ORDER BY cohort_year) AS change,
  100 * (avg_cohort_ltv - LAG(avg_cohort_ltv) OVER(ORDER BY cohort_year)) / avg_cohort_ltv AS rate
FROM cohort_final

````

![08 cohort ltv pipeline code](images/08_cohort_ltv_pipeline_code.png)

![09 cohort ltv pipeline results](images/09_cohort_ltv_pipeline_results.png)

Results across cohorts:

- 2015 Cohort: Average LTV of 5271.59 USD.
- 2016 Cohort: Average LTV of 5404.92 USD.
- 2017 Cohort: Average LTV of 5403.08 USD.
- 2018 Cohort: Average LTV of 4896.64 USD.
- 2019 Cohort: Average LTV of 4731.95 USD.
- 2020 Cohort: Average LTV of 3933.32 USD.
- 2021 Cohort: Average LTV of 3943.33 USD.
- 2022 Cohort: Average LTV of 3315.52 USD.
- 2023 Cohort: Average LTV of 2543.18 USD.
- 2024 Cohort: Average LTV of 2037.55 USD.

Older cohorts have had more years to accumulate repeat orders, reaching an LTV ceiling near 5400 USD. Newer cohorts start around 2000 USD and grow over time.

### Question 3 Retention and Loyalty Analysis Who Returns and Who Has Not Purchased Recently

#### Annual Cohort Retention Grid

This query measures customer retention by tracking how many customers from each acquisition cohort return to buy in later calendar years:


````sql
WITH y_c AS
(
  SELECT DISTINCT
    customerkey,
    EXTRACT(YEAR FROM MIN(orderdate) OVER(PARTITION BY customerkey)) AS cohort_date
  FROM sales
)
SELECT
  EXTRACT(YEAR FROM orderdate::date) AS year_date,
  cohort_date,
  COUNT(DISTINCT customerkey)
FROM sales
LEFT JOIN y_c USING (customerkey)
GROUP BY cohort_date,
         EXTRACT(YEAR FROM orderdate::date)
LIMIT 50

````

![10 cohort retention grid](images/10_cohort_retention_grid.png)

Tracking the 2015 cohort across nine years:

- 2015: 2825 customers acquired.
- 2016: 126 customers returned.
- 2017: 149 customers returned.
- 2018: 348 customers returned.
- 2019: 388 customers returned.
- 2020: 171 customers returned.
- 2021: 295 customers returned.
- 2022: 600 customers returned.
- 2023: 499 customers returned.
- 2024: 146 customers returned.

The return of 600 customers in 2022 highlights significant customer reactivation during the record sales expansion of that year.

#### Customer Order Frequency and Ranking Tie Handling

This query compares `ROW_NUMBER`, `RANK`, and `DENSE_RANK` to handle ties when ranking customers by order count:


````sql
SELECT
  customerkey,
  COUNT(*) AS total_orders,
  ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC ) AS total_orders_row_num,
  RANK() OVER (ORDER BY COUNT(*) DESC ) AS total_orders_rank,
  DENSE_RANK() OVER (ORDER BY COUNT(*) DESC ) AS total_orders_dense_rank
FROM sales
GROUP BY customerkey
LIMIT 10

````

![11 ranking functions comparison](images/11_ranking_functions_comparison.png)

Top order counts:

- Customer 1834524 placed 31 orders.
- Customer 1375597 placed 30 orders.
- Customer 249557 placed 27 orders.
- Customers 1495941, 459519, and 1801215 tied with 26 orders each. `RANK` assigned them all rank 4 and skipped to rank 7. `DENSE_RANK` assigned them rank 4 and moved to rank 5 without gaps.

#### Customer Lifetime Spend and Cohort Comparison

Comparing individual customer lifetime spend against the cohort average:


````sql
WITH y_c AS
(
  SELECT
    customerkey,
    EXTRACT(YEAR FROM MIN(orderdate)) AS cohort_date,
    SUM(netprice * quantity * exchangerate) AS customer_ltv
  FROM sales
  GROUP BY customerkey
)
SELECT
  *,
  AVG(customer_ltv) OVER(PARTITION BY cohort_date) AS avg_cohort_ltv
FROM y_c
ORDER BY customerkey
LIMIT 50

````

![12 customer ltv cohort avg](images/12_customer_ltv_cohort_avg.png)

This query identifies individual VIP customers. For example Customer 688 achieved an LTV of 16909.04 USD compared to the 2023 cohort average of 2543.18 USD.

#### Daily Active Customers by Continent in 2023

Pivoting daily active unique customers by continent using conditional aggregation:


````sql
SELECT
  s.orderdate AS date,
  COUNT(DISTINCT(s.customerkey)) AS total_customer,
  COUNT(DISTINCT CASE WHEN c.continent = 'North America' THEN s.customerkey END) AS na_customers,
  COUNT(DISTINCT CASE WHEN c.continent = 'Europe' THEN s.customerkey END) AS eu_customers,
  COUNT(DISTINCT CASE WHEN c.continent = 'Australia' THEN s.customerkey END) AS au_customers
FROM sales s
LEFT JOIN customer c USING (customerkey)
WHERE s.orderdate::date BETWEEN '2023/01/01' AND '2023/12/31'
GROUP BY s.orderdate
ORDER BY total_customer DESC

````

![13 daily customers geographic](images/13_daily_customers_geographic.png)

The highest customer traffic day was February 18 2023 with 157 unique customers: 100 from North America, 47 from Europe, and 10 from Australia.

## Product Category Analytics and Comparative Benchmarking

### Year over Year Category Revenue Comparison

Comparing 2022 and 2023 category revenue side by side:


````sql
SELECT
  p.categoryname AS category,
  ROUND(SUM(s.netprice * s.quantity * s.exchangerate)::numeric, 0) AS net_revenue,
  TO_CHAR(SUM(CASE WHEN s.orderdate BETWEEN '2022/01/01' AND '2022/12/31' THEN s.netprice * s.quantity * s.exchangerate END), 'FM999,999,999') AS yr_2022,
  TO_CHAR(SUM(CASE WHEN s.orderdate BETWEEN '2023/01/01' AND '2023/12/31' THEN s.netprice * s.quantity * s.exchangerate END), 'FM999,999,999') AS yr_2023
FROM sales s
LEFT JOIN product p USING (productkey)
WHERE s.orderdate BETWEEN '2022/01/01' AND '2023/12/31'
GROUP BY p.categoryname
ORDER BY net_revenue DESC

````

![14 yoy category revenue](images/14_yoy_category_revenue.png)

Revenue by category:

1. Computers: 29513081 USD (2022: 17862213 USD, 2023: 11650867 USD).
2. Cell phones: 14121813 USD (2022: 8119665 USD, 2023: 6002148 USD).
3. Home Appliances: 12532440 USD (2022: 6612447 USD, 2023: 5919993 USD).
4. TV and Video: 10227515 USD (2022: 5815337 USD, 2023: 4412178 USD).
5. Music, Movies and Audio Books: 5170065 USD.
6. Cameras and camcorders: 4366079 USD.
7. Audio: 1455628 USD.
8. Games and Toys: 586502 USD.

### Statistical Benchmarking Mean Median Min and Max


````sql
SELECT
  p.categoryname AS category,
  ROUND(SUM(s.netprice * s.quantity * s.exchangerate)::numeric, 0) AS avg_revenue,
  AVG(CASE WHEN s.orderdate BETWEEN '2022/01/01' AND '2022/12/31' THEN s.netprice * s.quantity * s.exchangerate END) AS avg_2022,
  AVG(CASE WHEN s.orderdate BETWEEN '2023/01/01' AND '2023/12/31' THEN s.netprice * s.quantity * s.exchangerate END) AS avg_2023,
  TO_CHAR(MAX(CASE WHEN s.orderdate BETWEEN '2022/01/01' AND '2022/12/31' THEN s.netprice * s.quantity * s.exchangerate END), 'FM999,999,999') AS max_2022,
  TO_CHAR(MAX(CASE WHEN s.orderdate BETWEEN '2023/01/01' AND '2023/12/31' THEN s.netprice * s.quantity * s.exchangerate END), 'FM999,999,999') AS max_2023,
  MIN(CASE WHEN s.orderdate BETWEEN '2022/01/01' AND '2022/12/31' THEN s.netprice * s.quantity * s.exchangerate END) AS min_2022,
  MIN(CASE WHEN s.orderdate BETWEEN '2023/01/01' AND '2023/12/31' THEN s.netprice * s.quantity * s.exchangerate END) AS min_2023
FROM sales s
LEFT JOIN product p USING (productkey)
WHERE s.orderdate BETWEEN '2022/01/01' AND '2023/12/31'
GROUP BY p.categoryname
ORDER BY avg_revenue DESC

````

![15 statistical benchmarking](images/15_statistical_benchmarking.png)

Comparing true medians across categories:


````sql
SELECT
  p.categoryname AS category,
  PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY (CASE WHEN s.orderdate BETWEEN '2022/01/01' AND '2022/12/31' THEN s.netprice * s.quantity * s.exchangerate END)) AS median_2022,
  PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY (CASE WHEN s.orderdate BETWEEN '2023/01/01' AND '2023/12/31' THEN s.netprice * s.quantity * s.exchangerate END)) AS median_2023
FROM sales s
LEFT JOIN product p USING (productkey)
WHERE s.orderdate BETWEEN '2022/01/01' AND '2023/12/31'
GROUP BY p.categoryname

````

![16 category median comparison](images/16_category_median_comparison.png)

In Computers for 2022, the average was 1565.62 USD while the median was 809.70 USD. This large difference indicates positive skewness caused by single transactions reaching up to 38083 USD.

### Dynamic Quartile Tiering and Spend Concentration

Calculating global percentiles across all transactions:


````sql
SELECT
  PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY (quantity * netprice * exchangerate)) AS Median_revenue
FROM sales

````

![17 global median revenue](images/17_global_median_revenue.png)

This returned a global median of 399.17 USD.

Using this median to segment category revenue into high and low brackets:


````sql
SELECT
  p.categoryname,
  TO_CHAR(SUM(CASE WHEN s.orderdate::date BETWEEN '2022/01/01' AND '2022/12/31' AND s.quantity * s.netprice * s.exchangerate >= 399.17 THEN s.quantity * s.netprice * s.exchangerate END), 'FM999,999,999') AS HIGH_REVENUE_2022,
  TO_CHAR(SUM(CASE WHEN s.orderdate::date BETWEEN '2022/01/01' AND '2022/12/31' AND s.quantity * s.netprice * s.exchangerate < 399.17 THEN s.quantity * s.netprice * s.exchangerate END), 'FM999,999,999') AS LOW_REVENUE_2022,
  TO_CHAR(SUM(CASE WHEN s.orderdate::date BETWEEN '2023/01/01' AND '2023/12/31' AND s.quantity * s.netprice * s.exchangerate >= 399.17 THEN s.quantity * s.netprice * s.exchangerate END), 'FM999,999,999') AS HIGH_REVENUE_2023,
  TO_CHAR(SUM(CASE WHEN s.orderdate::date BETWEEN '2023/01/01' AND '2023/12/31' AND s.quantity * s.netprice * s.exchangerate < 399.17 THEN s.quantity * s.netprice * s.exchangerate END), 'FM999,999,999') AS LOW_REVENUE_2023
FROM sales s
LEFT JOIN product p USING (productkey)
WHERE s.orderdate::date BETWEEN '2022/01/01' AND '2023/12/31'
GROUP BY p.categoryname

````

![18 high low revenue segmentation](images/18_high_low_revenue_segmentation.png)

Next the full quartile boundaries were computed:


````sql
SELECT
  PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY (quantity * netprice * exchangerate)) AS per_50th,
  PERCENTILE_CONT(.25) WITHIN GROUP (ORDER BY (quantity * netprice * exchangerate)) AS per_25th,
  PERCENTILE_CONT(.75) WITHIN GROUP (ORDER BY (quantity * netprice * exchangerate)) AS per_75th
FROM sales

````

![19 quartile thresholds](images/19_quartile_thresholds.png)

Thresholds:

- Q1 (25th Percentile): 105.40 USD
- Q2 (50th Percentile Median): 399.17 USD
- Q3 (75th Percentile): 1129.19 USD

The complete dynamic tiering query:


````sql
WITH per AS
(
  SELECT
    PERCENTILE_CONT(.25) WITHIN GROUP (ORDER BY (quantity * netprice * exchangerate)) AS per_25th,
    PERCENTILE_CONT(.75) WITHIN GROUP (ORDER BY (quantity * netprice * exchangerate)) AS per_75th
  FROM sales s
  WHERE orderdate::date BETWEEN '2022/01/01' AND '2023/12/31'
)

SELECT
  p.categoryname AS category,
  CASE WHEN (s.quantity * s.netprice * s.exchangerate) <= per.per_25th THEN 'LOW'
       WHEN (s.quantity * s.netprice * s.exchangerate) >= per.per_75th THEN 'HIGH'
       ELSE 'MEDIAN'
  END AS tier,
  TO_CHAR(SUM(s.quantity * s.netprice * s.exchangerate), 'FM999,999,999') AS total_revenue
FROM sales s
LEFT JOIN product p USING (productkey)
CROSS JOIN per
WHERE orderdate::date BETWEEN '2022/01/01' AND '2023/12/31'
GROUP BY p.categoryname,
         tier
ORDER BY category

````

![20 quartile tiering code](images/20_quartile_tiering_code.png)

![21 quartile tiering results](images/21_quartile_tiering_results.png)

Complete 24 Row Distribution:

- Audio: HIGH 453109 USD, LOW 49819 USD, MEDIAN 952700 USD.
- Cameras and camcorders: HIGH 3414877 USD, LOW 21788 USD, MEDIAN 929414 USD.
- Cell phones: HIGH 8557889 USD, LOW 206224 USD, MEDIAN 5357700 USD.
- Computers: HIGH 24192945 USD, LOW 114336 USD, MEDIAN 5205799 USD.
- Games and Toys: HIGH 34626 USD, LOW 190548 USD, MEDIAN 361328 USD.
- Home Appliances: HIGH 10851234 USD, LOW 34522 USD, MEDIAN 1646683 USD.
- Music, Movies and Audio Books: HIGH 2074183 USD, LOW 278524 USD, MEDIAN 2817359 USD.
- TV and Video: HIGH 8406607 USD, LOW 24617 USD, MEDIAN 1796291 USD.

In Computers, Home Appliances, and TV and Video, more than 80 percent of revenue comes from orders above the 75th percentile (HIGH tier). In contrast, Games and Toys generated its highest revenue in the MEDIAN and LOW tiers.

## Operational Logistics and Supply Chain Analysis

### Order to Delivery Lead Time Analysis

Measuring fulfillment time using PostgreSQL `AGE`:


````sql
SELECT
  EXTRACT(YEAR FROM orderdate) AS order_year,
  ROUND(AVG(EXTRACT(DAY FROM AGE(deliverydate, orderdate))), 2) AS avg_processing_time,
  PERCENTILE_CONT(.5) WITHIN GROUP ( ORDER BY (EXTRACT(DAY FROM AGE(deliverydate, orderdate)))) AS median_processing_time,
  TO_CHAR(SUM(netprice * quantity * exchangerate), 'FM999,999,999') AS multinqe
FROM sales

GROUP BY order_year

````

![22 supply chain lead time](images/22_supply_chain_lead_time.png)

Fulfillment Metrics Across Ten Years:

- 2015: Average 1.10 days, Median 0.00 days, Revenue 7370979 USD.
- 2016: Average 1.08 days, Median 0.00 days, Revenue 10383614 USD.
- 2017: Average 0.83 days, Median 0.00 days, Revenue 13221339 USD.
- 2018: Average 0.86 days, Median 0.00 days, Revenue 24667448 USD.
- 2019: Average 0.81 days, Median 0.00 days, Revenue 31818096 USD.
- 2020: Average 0.93 days, Median 0.00 days, Revenue 11218436 USD.
- 2021: Average 1.36 days, Median 0.00 days, Revenue 21357977 USD.
- 2022: Average 1.62 days, Median 1.00 days, Revenue 44864557 USD.
- 2023: Average 1.75 days, Median 2.00 days, Revenue 33108566 USD.
- 2024: Average 1.67 days, Median 1.00 days, Revenue 8396527 USD.

### Supply Chain Bottlenecks During Sales Peaks

Between 2015 and 2021 the median fulfillment time was 0.00 days, meaning over half of all orders were delivered on the same day. In 2022, annual revenue surged to a record 44864557 USD. As a result, average delivery time rose to 1.62 days and median processing time rose to 1.00 day, peaking in 2023 at 1.75 days average and 2.00 days median. This proves that high sales volume created fulfillment bottlenecks.

## Time Series Modeling and Trend Smoothing

### Long Term Macro Growth Across 112 Months


````sql
SELECT
  DATE_TRUNC('month', orderdate)::date AS orderdate_month,
  TO_CHAR(SUM(netprice * quantity * exchangerate), 'FM999,999,999') AS total_revenue,
  COUNT(DISTINCT customerkey) AS total_customers
FROM sales
GROUP BY orderdate_month

````

![23 monthly time series](images/23_monthly_time_series.png)

This query tracked 112 months from January 2015 to April 2024. In 2015 monthly revenue ranged from 160767 USD to 706374 USD with 78 to 291 active customers. By February 2024, monthly revenue reached a record 3542323 USD with 1718 active customers.

### Discrete Date Extraction with Extract


````sql
SELECT
  TO_CHAR(SUM(netprice * quantity * exchangerate), 'FM999,999,999') AS total_revenue,
  EXTRACT(YEAR FROM orderdate) AS orderdate_year,
  EXTRACT(MONTH FROM orderdate) AS orderdate_month
FROM sales
GROUP BY
  orderdate_year,
  orderdate_month
ORDER BY
  orderdate_year,
  orderdate_month

````

![24 extract year month](images/24_extract_year_month.png)

This query provides separate columns for year and month, ready for spreadsheet and dashboard reporting.

### Granular Daily Tracking and Audit Timestamps


````sql
SELECT
  TO_CHAR(NOW(), 'YYYY/mm/dd') AS current_date,
  TO_CHAR(s.orderdate, 'YYYY/mm/dd') AS orderdate,
  p.categoryname,
  SUM(s.netprice * s.quantity * s.exchangerate) AS total_revenue
FROM sales s
LEFT JOIN product p USING (productkey)
WHERE orderdate >= '2020/01/01'
GROUP BY orderdate,
         p.categoryname
ORDER BY orderdate

````

![25 daily category feed](images/25_daily_category_feed.png)

This query produced 11171 rows, attaching execution timestamps to daily category figures.

### Dynamic Rolling Five Year Windows


````sql
SELECT
  TO_CHAR(NOW(), 'YYYY/mm/dd') AS current_date,
  TO_CHAR(s.orderdate, 'YYYY/mm/dd') AS orderdate,
  p.categoryname,
  SUM(s.netprice * s.quantity * s.exchangerate) AS total_revenue
FROM sales s

LEFT JOIN product p USING (productkey)

WHERE orderdate >= current_date - INTERVAL '5 years'

GROUP BY orderdate,
         p.categoryname

ORDER BY orderdate

````

![26 rolling window output](images/26_rolling_window_output.png)

Executed on October 1 2026, the query dynamically set its starting boundary to October 1 2021, returning 7129 rows without requiring manual date edits.

### Month over Month Growth and Performance Swings


````sql
WITH monthly_revenue AS
(
  SELECT
    TO_CHAR(orderdate, 'yyyy/mm') AS date,
    SUM(netprice * quantity * exchangerate) AS net_revenue
  FROM sales
  WHERE EXTRACT(YEAR FROM orderdate) = 2023
  GROUP BY date
  ORDER BY date
)

SELECT
  *,
  LAG(net_revenue) OVER(ORDER BY date) AS p_month_revenue,
  net_revenue - LAG(net_revenue) OVER(ORDER BY date) AS monthly_rev_grouth,
  100 * (net_revenue - LAG(net_revenue) OVER(ORDER BY date)) / LAG(net_revenue) OVER(ORDER BY date) AS rate
FROM monthly_revenue

````

![27 mom growth rates](images/27_mom_growth_rates.png)

Monthly Swings in 2023:

- February grew 21.85 percent to 4465204.57 USD.
- March and April dropped by negative 49.74 percent and negative 48.19 percent to 1162796.16 USD.
- May rebounded by 153.10 percent, gaining 1.78 million USD in a single month to reach 2943005.99 USD.

### Reference Benchmarks with First Last and Nth Value


````sql
WITH monthly_revenue AS
(
  SELECT
    TO_CHAR(orderdate, 'yyyy/mm') AS date,
    TO_CHAR(SUM(netprice * quantity * exchangerate), 'FM999,999,999') AS net_revenue
  FROM sales
  WHERE EXTRACT(YEAR FROM orderdate) = 2023
  GROUP BY date
  ORDER BY date
)

SELECT
  *,
  FIRST_VALUE(net_revenue) OVER(ORDER BY date) AS first_month_revenue,
  LAST_VALUE(net_revenue) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_month_revenue,
  NTH_VALUE(net_revenue, 7 ) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS seventh_month_revenue
FROM monthly_revenue

````

![28 value window functions](images/28_value_window_functions.png)


````sql
WITH monthly_revenue AS
(
  SELECT
    TO_CHAR(orderdate, 'yyyy/mm') AS date,
    TO_CHAR(SUM(netprice * quantity * exchangerate), 'FM999,999,999') AS net_revenue
  FROM sales
  WHERE EXTRACT(YEAR FROM orderdate) = 2023
  GROUP BY date
  ORDER BY date
)

SELECT
  *,
  LAG(net_revenue) OVER(ORDER BY date) AS p_month_revenue,
  LEAD(net_revenue) OVER(ORDER BY date) AS n_month_revenue
FROM monthly_revenue

````

![29 lag lead output](images/29_lag_lead_output.png)

These queries verified benchmark figures for 2023: January opened at 3664431 USD, July mid year reached 2337639 USD, and December closed at 2928551 USD.

### Three Month Centered Moving Average Smoothing


````sql
WITH m_r AS
(
  SELECT
    TO_CHAR(orderdate, 'yyyy/mm') AS date,
    SUM(netprice * quantity * exchangerate) AS net_revenue
  FROM sales

  WHERE EXTRACT(YEAR FROM orderdate) = 2023

  GROUP BY date

  ORDER BY date
),

final AS
(
  SELECT
    date,
    net_revenue,
    AVG(net_revenue) OVER(ORDER BY date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
  FROM m_r
)

SELECT *
FROM final

````

![30 moving average smoothing](images/30_moving_average_smoothing.png)

While April dropped to 1.16 million USD, the moving average showed that the business baseline remained at 2.11 million USD, stabilizing around 2.6 million USD in the second half of the year.

## Customer Trajectory and Cart Depth Dynamics

### Cumulative Customer Spending Velocity


````sql
SELECT
  customerkey,
  orderdate,
  netprice * quantity * exchangerate AS net_revenue,
  AVG(netprice * quantity * exchangerate) OVER(
    PARTITION BY customerkey
    ORDER BY orderdate
  ) AS running_order_avg,
  COUNT(*) OVER(
    PARTITION BY customerkey
    ORDER BY orderdate
  ) AS running_order_count

FROM sales

ORDER BY customerkey

LIMIT 50

````

![31 running spend velocity](images/31_running_spend_velocity.png)

Customer 387 progression:

- Started on December 21 2018 with 4 items averaging 592.64 USD.
- Purchased a 1265.56 USD item on October 30 2021, raising their running average to 727.22 USD.
- Reached 9 items by November 16 2023, stabilizing at 517.32 USD.

### Cart Depth and Line Item Revenue Drop Off


````sql
WITH n_r AS
(
  SELECT
    linenumber,
    orderdate,
    SUM(netprice * quantity * exchangerate) OVER(PARTITION BY linenumber, orderdate::date) AS net_revenue,
    SUM(netprice * quantity * exchangerate) OVER(PARTITION BY orderdate::date) AS daily_net_revenue
  FROM sales
)

SELECT *,
  net_revenue / daily_net_revenue * 100 AS pct_daily_net_revenue
FROM n_r

ORDER BY orderdate,
         linenumber

LIMIT 50

````

![32 cart depth dropoff](images/32_cart_depth_dropoff.png)

On January 1 2015, line 1 generated 35.19 percent of revenue, line 2 generated 13.81 percent, and line 3 generated 22.30 percent, while lines 4 and 5 dropped to 0.58 percent and 0.32 percent.

## Database Views and Semantic Modeling

To encapsulate business calculations and make them reusable, two database views were created in DBeaver.

### Daily Revenue View


````sql
CREATE VIEW daily_revenue AS
SELECT
  orderdate,
  TO_CHAR(SUM(netprice * quantity * exchangerate), 'FM999,999,999')
FROM sales

GROUP BY orderdate

ORDER BY orderdate

````

![33 create view daily revenue](images/33_create_view_daily_revenue.png)


````sql
SELECT *
FROM daily_revenue dr

````

![34 query view daily revenue](images/34_query_view_daily_revenue.png)

This view provides daily total revenue with proper formatting in a single call.

### Valuable Customers Profile View

The view `cs_valubale_customers_info` was created to combine customer demographics with daily transaction metrics. This view served as the foundation for answering Question 2.

## Comprehensive Business Insights and Findings

1. VIP Spenders Drive Significant Revenue Top spenders like Ben Davenport (82057 USD) and Peter Rodriguez (79201 USD) generate massive value. Retail management should provide dedicated VIP account managers and priority logistics for this group.
2. Product Categories Require Different Merchandising Strategies Categories like Computers, Home Appliances, and TV and Video generate over 80 percent of their revenue from orders above the 75th percentile (1129 USD). In contrast, Games and Toys and Audio generate their revenue primarily in lower and median tiers. High ticket categories benefit from financing plans, while lower priced categories benefit from multi item bundling.
3. Predictable Lifetime Value Ceiling Mature cohorts consistently reach an average lifetime value ceiling near 5400 USD. Newer cohorts from 2022 to 2024 currently average between 2000 USD and 3300 USD, providing a reliable baseline for revenue forecasting.
4. Logistics Infrastructure Must Scale with Sales The record sales volume of 44.8 million USD in 2022 doubled delivery lead times from same day shipping to nearly two days. Fulfillment capacity must expand prior to launching major promotions.
5. Moving Averages Provide a Clear Baseline Monthly revenue in 2023 fluctuated between negative 49 percent and positive 153 percent. A three month centered moving average revealed a stable baseline between 2.1 million USD and 2.6 million USD, preventing overreaction to seasonal drops.

## Tools and Technologies

- Database Management System: PostgreSQL
- Database Client and GUI: DBeaver 26.2.2
- Interactive Development Environment: Google Colab with ipython sql extension
- Sample Dataset: Microsoft Contoso Database (100k records)
- SQL Skills Used: Multi Stage Common Table Expressions, Window Functions, Continuous Ordered Set Percentiles, Interval Date Arithmetic, Multi Table Joins, and DDL Database Views
