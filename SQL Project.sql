USE project;  -- selecting the database in which we are going to perform different tasks

SELECT * FROM walmartsales; -- getting the overview of data

DESC walmartsales; -- viewing the structure of the table walmartsales

ALTER TABLE walmartsales ADD COLUMN new_date date AFTER Total; -- adding the a new column new_date beacuse date column is text here 

UPDATE walmartsales SET new_date = str_to_date(Date, '%d-%m-%Y'); -- update the added column 

ALTER TABLE walmartsales DROP COLUMN Date; -- delete the date column, because it is extra after creation of new_date column

/* Task 1: Identifying the Top Branch by Sales Growth Rate (6 Marks)
Walmart wants to identify which branch has exhibited the highest sales growth over time. Analyze the total sales
for each branch and compare the growth rate across months to find the top performer. */
WITH MonthlySales AS (
    SELECT Branch, DATE_FORMAT(new_date,'%Y-%m') AS sales_month, SUM(Total) AS total_sales
    FROM walmartsales
    GROUP BY Branch, sales_month ),
GrowthRate AS (
    SELECT Branch, sales_month, total_sales,
        LAG(total_sales) OVER (PARTITION BY Branch ORDER BY sales_month) AS prev_sales,
        ((total_sales - LAG(total_sales) OVER (PARTITION BY Branch ORDER BY sales_month)) / 
        LAG(total_sales) OVER (PARTITION BY Branch ORDER BY sales_month)) * 100 AS growth_rate
    FROM MonthlySales
)
SELECT Branch, AVG(growth_rate) AS avg_growth_rate
FROM GrowthRate
WHERE growth_rate IS NOT NULL
GROUP BY Branch
ORDER BY avg_growth_rate DESC
LIMIT 1;
            
/* Task 2: Finding the Most Profitable Product Line for Each Branch (6 Marks)
Walmart needs to determine which product line contributes the highest profit to each branch.The profit margin
should be calculated based on the difference between the gross income and cost of goods sold. */
SELECT Branch, `Product line` AS Product_line, ROUND(SUM(`gross income` - cogs),2) AS total_profit
FROM walmartsales
GROUP BY Branch, `Product line`
HAVING total_profit = (
    SELECT MAX(profit)
    FROM (
        SELECT Branch, `Product line`, ROUND(SUM(`gross income` - cogs),2) AS profit
        FROM walmartsales
        GROUP BY Branch, `Product line`
    ) AS subquery
    WHERE subquery.Branch = walmartsales.Branch
);

/* Task 3: Analyzing Customer Segmentation Based on Spending (6 Marks)
Walmart wants to segment customers based on their average spending behavior. Classify customers into three
tiers: High, Medium, and Low spenders based on their total purchase amounts. */
WITH CustomerSpending AS (
    SELECT `Customer ID`, ROUND(SUM(Total),2) AS total_spent
    FROM walmartsales
    GROUP BY `Customer ID`
)
SELECT `Customer ID`, total_spent,
    CASE 
        WHEN total_spent > 20000 THEN 'High'
        WHEN total_spent BETWEEN 15000 AND 20000 THEN 'Medium'
        ELSE 'Low'
    END AS spenders_type
FROM CustomerSpending;

/* Task 4: Detecting Anomalies in Sales Transactions (6 Marks)
Walmart suspects that some transactions have unusually high or low sales compared to the average for the product line. Identify these anomalies. */
WITH ProductStats AS (
    SELECT `Product line`, ROUND(AVG(Total),2) AS avg_sales, ROUND(STDDEV(Total),2) AS std_dev_sales
    FROM walmartsales
    GROUP BY `Product line`
)
SELECT s.`Invoice ID`, s.`Product line`, s.Total, p.avg_sales, p.std_dev_sales,
    CASE 
        WHEN s.Total > (p.avg_sales + 2 * p.std_dev_sales) THEN 'High Anomaly'
        WHEN s.Total < (p.avg_sales - 2 * p.std_dev_sales) THEN 'Low Anomaly'
        ELSE 'Normal'
    END AS anomaly_status
FROM walmartsales s
JOIN ProductStats p 
ON s.`Product line` = p.`Product line`
WHERE s.Total > (p.avg_sales + 2 * p.std_dev_sales) 
   OR s.Total < (p.avg_sales - 2 * p.std_dev_sales);

/* Task 5: Most Popular Payment Method by City (6 Marks)
Walmart needs to determine the most popular payment method in each city to tailor marketing strategies. */
WITH PaymentRank AS (
    SELECT City, Payment, COUNT(*) AS total_count, RANK() OVER (PARTITION BY City ORDER BY COUNT(*) DESC) AS rnk
    FROM walmartsales
    GROUP BY City, Payment
)
SELECT City, Payment, total_count
FROM PaymentRank
WHERE rnk = 1;

/* Task 6: Monthly Sales Distribution by Gender (6 Marks)
Walmart wants to understand the sales distribution between male and female customers on a monthly basis. */
SELECT 
    DATE_FORMAT(new_date, '%Y-%m') AS month, Gender, ROUND(SUM(Total),2) AS total_sales
FROM walmartsales
GROUP BY month, Gender
ORDER BY month, total_sales DESC;

/* Task 7: Best Product Line by Customer Type (6 Marks)
Walmart wants to know which product lines are preferred by different customer types(Member vs. Normal). */
WITH ProductRanking AS (
    SELECT `Customer type`, `Product line`, COUNT(*) AS purchase_count, 
    RANK() OVER (PARTITION BY `Customer type` ORDER BY COUNT(*) DESC) AS rnk
    FROM walmartsales
    GROUP BY `Customer type`, `Product line`
)
SELECT `Customer type`, `Product line`, purchase_count
FROM ProductRanking;

/* Task 8: Identifying Repeat Customers (6 Marks)
Walmart needs to identify customers who made repeat purchases within a specific time frame (e.g., within 30 days). */
SELECT `Customer ID`, COUNT(*) AS Num_Repeat_Purchases
FROM walmartsales
GROUP BY `Customer ID`
HAVING COUNT(*) > 1;

/* Task 9: Finding Top 5 Customers by Sales Volume (6 Marks)
Walmart wants to reward its top 5 customers who have generated the most sales Revenue. */
SELECT `Customer ID`, ROUND(SUM(Total),2) AS total_revenue
FROM walmartsales
GROUP BY `Customer ID`
ORDER BY total_revenue DESC
LIMIT 5;

/* Task 10: Analyzing Sales Trends by Day of the Week (6 Marks)
Walmart wants to analyze the sales patterns to determine which day of the week brings the highest sales. */
SELECT DAYNAME(new_date) AS Day_of_Week, round(SUM(Total),2) AS Total_Sales
FROM walmartsales
GROUP BY day_of_week
ORDER BY total_sales DESC;
