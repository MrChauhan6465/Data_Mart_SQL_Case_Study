SELECT * FROM clean_weekly_sales;


2. Data Exploration
1. What day of the week is used for each week_date value?;


SELECT DISTINCT (TO_CHAR(week_date,'Day')) AS Week_Day
    FROM clean_weekly_sales;

2. What range of week numbers are missing from the dataset?;

WITH week_number_cte AS (
  SELECT GENERATE_SERIES(1,52) AS week_number
)
  
SELECT DISTINCT week_no.week_number
FROM week_number_cte AS week_no
LEFT JOIN clean_weekly_sales AS sales
  ON week_no.week_number = sales.week_number
WHERE sales.week_number IS NULL; -- Filter to identify the missing week numbers where the values are `NULL`.


3. How many total transactions were there for each year in the dataset?;

SELECT calendar_year,SUM(transactions) AS total_transactions FROM clean_weekly_sales
group by 1
ORDER BY total_transactions DESC ;

4. What is the total sales for each region for each month?;

SELECT 
  month_number, 
  region, 
  SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY month_number, region
ORDER BY month_number, region;


5. What is the total count of transactions for each platform?;

SELECT 
  platform, 
  SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;

6. What is the percentage of sales for Retail vs Shopify for each month?;

WITH monthly_transactions AS (
  SELECT 
    calendar_year, 
    month_number, 
    platform, 
    SUM(sales) AS monthly_sales
  FROM clean_weekly_sales
  GROUP BY calendar_year, month_number, platform
)

SELECT 
  calendar_year, 
  month_number, 
  ROUND(100 * MAX 
    (CASE 
      WHEN platform = 'Retail' THEN monthly_sales ELSE NULL END) 
    / SUM(monthly_sales),2) AS retail_percentage,
  ROUND(100 * MAX 
    (CASE 
      WHEN platform = 'Shopify' THEN monthly_sales ELSE NULL END)
    / SUM(monthly_sales),2) AS shopify_percentage
FROM monthly_transactions
GROUP BY calendar_year, month_number
ORDER BY calendar_year, month_number;


7. What is the percentage of sales by demographic for each year in the dataset?;

WITH demographic_sales AS (
  SELECT 
    calendar_year, 
    demographic, 
    SUM(sales) AS yearly_sales
  FROM clean_weekly_sales
  GROUP BY calendar_year, demographic
)

SELECT 
  calendar_year, 
  ROUND(100 * MAX 
    (CASE 
      WHEN demographic = 'Couples' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS couples_percentage,
  ROUND(100 * MAX 
    (CASE 
      WHEN demographic = 'Families' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS families_percentage,
  ROUND(100 * MAX 
    (CASE 
      WHEN demographic = 'unknown' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS unknown_percentage
FROM demographic_sales
GROUP BY calendar_year;


8. Which age_band and demographic values contribute the most to Retail sales?;

SELECT age_band,demographic,sum(sales) AS Retail_Sales,
    ROUND(100 * 
    SUM(sales)::NUMERIC 
    / SUM(SUM(sales)) OVER (),
  1) AS contribution_percentage
    FROM clean_weekly_sales
    WHERE platform = 'Retail'
    GROUP BY 1,2
    ORDER BY Retail_Sales Desc

9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?;

SELECT 
  calendar_year, 
  platform, 
  ROUND(AVG(avg_transaction),0) AS avg_transaction_row, 
  SUM(sales) / sum(transactions) AS avg_transaction_group
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;

The difference between avg_transaction_row and avg_transaction_group is as follows:

avg_transaction_row calculates the average transaction size by dividing the sales of each row by the number of transactions in that row.
On the other hand, avg_transaction_group calculates the average transaction size by dividing the total sales for the entire dataset by the total number of transactions.
For finding the average transaction size for each year by platform accurately, it is recommended to use avg_transaction_group.



3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:

1.	What is the total sales for the 4 weeks before and after 2020-06-15? 
What is the growth or reduction rate in actual values and percentage of sales?;

NOTE: 2020-06-15 Week_number is 25 

WITH Packaging_sales as (
SELECT 
    week_date,
    week_number,
    SUM(sales) as total_sales 
FROM 
    clean_weekly_sales
WHERE  
    week_number BETWEEN 21 AND 28 
    AND calendar_year = 2020
GROUP BY 
    1, 2
),Before_After_sales as
 ( SELECT 
     SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN total_sales  END) AS Before_packaging_sales,
     SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN total_sales  END) AS After_packaging_sales
     FROM Packaging_sales    
)
SELECT (After_packaging_sales - Before_packaging_sales) Variance,
        ROUND(((After_packaging_sales-Before_packaging_sales)/Before_packaging_sales)*100,2) variance_percentage
      FROM Before_After_sales;

NOTE:Since the implementation of the new sustainable packaging, there has been a decrease in sales amounting by $26,884,188 reflecting a negative change at 1.15%. Introducing a new packaging does not always guarantee positive results as customers may not readily recognise your product on the shelves due to the change in packaging.

2.	What about the entire 12 weeks before and after?

WITH Packaging_sales as (
SELECT 
    week_date,
    week_number,
    SUM(sales) as total_sales 
FROM 
    clean_weekly_sales
WHERE  
    week_number BETWEEN 13 AND 37
    AND calendar_year = 2020
GROUP BY 
    1, 2
),Before_After_sales as
 ( SELECT 
     SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN total_sales  END) AS Before_packaging_sales,
     SUM(CASE WHEN week_number BETWEEN 25 AND 37 THEN total_sales  END) AS After_packaging_sales
     FROM Packaging_sales    
)
SELECT (After_packaging_sales - Before_packaging_sales) Variance,
        ROUND(((After_packaging_sales-Before_packaging_sales)/Before_packaging_sales)*100,2) variance_percentage
      FROM Before_After_sales;


3.	How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

Part 1: How do the sale metrics for 4 weeks before and after compare with the previous years in 2018 and 2019?

Basically, the question is asking us to find the sales variance between 4 weeks before and after '2020-06-15' for years 2018, 2019 and 2020. Perhaps we can find a pattern here.
We can apply the same solution as above and add calendar_year into the syntax.;


WITH Packaging_sales as (
SELECT 
    week_date,
    week_number,calendar_year,
    SUM(sales) as total_sales 
FROM 
    clean_weekly_sales
WHERE  
    week_number BETWEEN 21 AND 28 
    AND calendar_year in (2020,2019,2018)

GROUP BY 
    1, 2,3
),Before_After_sales as
 ( SELECT calendar_year,
     SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN total_sales  END) AS Before_packaging_sales,
     SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN total_sales  END) AS After_packaging_sales
     FROM Packaging_sales   
     group by 1  
)
SELECT calendar_year , (After_packaging_sales - Before_packaging_sales) Variance,
        ROUND(((After_packaging_sales-Before_packaging_sales)/Before_packaging_sales)*100,2) variance_percentage
      FROM Before_After_sales;

Part 2: How do the sale metrics for 12 weeks before and after compare with the previous years in 2018 and 2019?

Use the same solution above and change to week 13 to 24 for before and week 25 to 37 for after.;

WITH Packaging_sales as (
SELECT 
    week_date,
    week_number,calendar_year,
    SUM(sales) as total_sales 
FROM 
    clean_weekly_sales
WHERE  
    week_number BETWEEN 13 AND 37
    AND calendar_year in (2020,2019,2018)
GROUP BY 
    1, 2,3
),Before_After_sales as
 ( SELECT calendar_year,
     SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN total_sales  END) AS Before_packaging_sales,
     SUM(CASE WHEN week_number BETWEEN 25 AND 37 THEN total_sales  END) AS After_packaging_sales
     FROM Packaging_sales    
     GROUP BY calendar_year
)
SELECT calendar_year,(After_packaging_sales - Before_packaging_sales) Variance,
        ROUND(((After_packaging_sales-Before_packaging_sales)/Before_packaging_sales)*100,2) variance_percentage
      FROM Before_After_sales;


4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type;

WITH twelve_weeks_before AS (
  SELECT DISTINCT week_date
  FROM clean_weekly_sales
  WHERE week_date BETWEEN (TO_DATE('2020-06-15', 'yy/mm/dd') - interval '12 weeks') AND 
  (TO_DATE('2020-06-15', 'yy/mm/dd') - interval '1 week')
),
twelve_weeks_after AS (
  SELECT DISTINCT week_date
  FROM clean_weekly_sales
  WHERE week_date BETWEEN TO_DATE('2020-06-15', 'yy/mm/dd') AND 
  (TO_DATE('2020-06-15', 'yy/mm/dd') + interval '11 weeks') 
),
summations AS (
  SELECT demographic, SUM(CASE WHEN week_date in (select * from twelve_weeks_before) THEN sales END) AS twelve_weeks_before,
  SUM(CASE WHEN week_date in (select * from twelve_weeks_after) THEN sales END) AS twelve_weeks_after
  FROM clean_weekly_sales
  GROUP BY demographic
)
SELECT *,
  twelve_weeks_after - twelve_weeks_before AS variance,
  ROUND(100 * (twelve_weeks_after - twelve_weeks_before)::numeric/twelve_weeks_after, 2) AS percentage_change
FROM summations
ORDER BY percentage_change;