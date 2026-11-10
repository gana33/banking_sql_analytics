#14. Which 10 customers have the highest total successful transaction value? 


SELECT
    c.customer_id,
    c.customer_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_transaction_value
FROM customers c
JOIN accounts a
    ON a.customer_id = c.customer_id
JOIN transactions t
    ON t.account_id = a.account_id
WHERE t.status = 'Success'
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY total_transaction_value DESC
LIMIT 10;


#15 Which customers have more than one account?

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(a.account_id) AS total_accounts
FROM customers c
JOIN accounts a
    ON a.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING COUNT(a.account_id) > 1
ORDER BY total_accounts DESC;

#16 Which customers have never made a successful transaction?

SELECT
    c.customer_id,
    c.customer_name
FROM customers c
JOIN accounts a
    ON a.customer_id = c.customer_id
LEFT JOIN transactions t
    ON t.account_id = a.account_id
    AND t.status = 'Success'
WHERE t.transaction_id IS NULL
GROUP BY
    c.customer_id,
    c.customer_name;
    
 #17 Which customers have transaction values above their branch's average?
 
 
WITH customer_transactions AS (
    SELECT
        b.branch_id,
        b.branch_name,
        c.customer_id,
        c.customer_name,
        SUM(t.amount) AS total_transaction_value
    FROM branches b
    JOIN accounts a
        ON a.branch_id = b.branch_id
    JOIN customers c
        ON c.customer_id = a.customer_id
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
    GROUP BY
        b.branch_id,
        b.branch_name,
        c.customer_id,
        c.customer_name
),

branch_average AS (
    SELECT
        branch_id,
        AVG(total_transaction_value) AS average_transaction_value
    FROM customer_transactions
    GROUP BY branch_id
)

SELECT
    ct.branch_id,
    ct.branch_name,
    ct.customer_id,
    ct.customer_name,
    ct.total_transaction_value,
    ROUND(ba.average_transaction_value, 2)
        AS branch_average
FROM customer_transactions ct
JOIN branch_average ba
    ON ct.branch_id = ba.branch_id
WHERE ct.total_transaction_value >
      ba.average_transaction_value
ORDER BY ct.total_transaction_value DESC;


#18 Which customers have stopped transacting recently?


WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.customer_name,
        MAX(t.transaction_date) AS last_transaction_date,
        COUNT(t.transaction_id) AS total_transactions
    FROM customers c
    JOIN accounts a
        ON a.customer_id = c.customer_id
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
    GROUP BY
        c.customer_id,
        c.customer_name
)

SELECT
    customer_id,
    customer_name,
    last_transaction_date,
    total_transactions,
    DATEDIFF(CURDATE(), last_transaction_date)
        AS days_since_last_transaction
FROM customer_activity
WHERE last_transaction_date < DATE_SUB(CURDATE(), INTERVAL 90 DAY)
ORDER BY last_transaction_date ASC;


#19 Which customers made the highest individual transaction, and when did it occur?


SELECT
    c.customer_id,
    c.customer_name,
    t.transaction_id,
    t.amount AS highest_transaction_amount,
    t.transaction_date
FROM customers c
JOIN accounts a
    ON a.customer_id = c.customer_id
JOIN transactions t
    ON t.account_id = a.account_id
WHERE t.status = 'Success'
  AND t.amount = (
      SELECT MAX(amount)
      FROM transactions
      WHERE status = 'Success'
  )
ORDER BY t.transaction_date DESC;


#20 Which customers made transactions on three consecutive days?


WITH customer_dates AS (
    SELECT DISTINCT
        c.customer_id,
        c.customer_name,
        DATE(t.transaction_date) AS transaction_day
    FROM customers c
    JOIN accounts a
        ON a.customer_id = c.customer_id
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
),

date_analysis AS (
    SELECT
        customer_id,
        customer_name,
        transaction_day,

        LAG(transaction_day, 1) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_day
        ) AS previous_day,

        LAG(transaction_day, 2) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_day
        ) AS two_days_before

    FROM customer_dates
)

SELECT DISTINCT
    customer_id,
    customer_name
FROM date_analysis
WHERE DATEDIFF(transaction_day, previous_day) = 1
  AND DATEDIFF(previous_day, two_days_before) = 1;


#21 Which customers increased their transaction value month over month?

WITH monthly_customer_transactions AS (
    SELECT
        c.customer_id,
        c.customer_name,
        YEAR(t.transaction_date) AS transaction_year,
        MONTH(t.transaction_date) AS transaction_month,
        SUM(t.amount) AS monthly_amount
    FROM customers c
    JOIN accounts a
        ON a.customer_id = c.customer_id
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
    GROUP BY
        c.customer_id,
        c.customer_name,
        YEAR(t.transaction_date),
        MONTH(t.transaction_date)
),

customer_growth AS (
    SELECT
        customer_id,
        customer_name,
        transaction_year,
        transaction_month,
        monthly_amount,

        LAG(monthly_amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_year, transaction_month
        ) AS previous_month_amount

    FROM monthly_customer_transactions
)

SELECT
    customer_id,
    customer_name,
    transaction_year,
    transaction_month,
    previous_month_amount,
    monthly_amount,
    ROUND(
        (monthly_amount - previous_month_amount)
        / NULLIF(previous_month_amount, 0) * 100,
        2
    ) AS growth_percentage
FROM customer_growth
WHERE monthly_amount > previous_month_amount
ORDER BY customer_id, transaction_year, transaction_month;

#22 Which customers experienced more than a 50% increase in monthly transaction value?
 
WITH monthly_customer_transactions AS (
    SELECT
        c.customer_id,
        c.customer_name,
        YEAR(t.transaction_date) AS transaction_year,
        MONTH(t.transaction_date) AS transaction_month,
        SUM(t.amount) AS monthly_amount
    FROM customers c
    JOIN accounts a
        ON a.customer_id = c.customer_id
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
    GROUP BY
        c.customer_id,
        c.customer_name,
        YEAR(t.transaction_date),
        MONTH(t.transaction_date)
),

customer_growth AS (
    SELECT
        customer_id,
        customer_name,
        transaction_year,
        transaction_month,
        monthly_amount,

        LAG(monthly_amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_year, transaction_month
        ) AS previous_month_amount
    FROM monthly_customer_transactions
)

SELECT
    customer_id,
    customer_name,
    transaction_year,
    transaction_month,
    previous_month_amount,
    monthly_amount,

    ROUND(
        (monthly_amount - previous_month_amount)
        / NULLIF(previous_month_amount, 0) * 100,
        2
    ) AS growth_percentage

FROM customer_growth
WHERE previous_month_amount > 0
  AND monthly_amount > previous_month_amount * 1.50
ORDER BY growth_percentage DESC;



#23 How can customers be segmented based on transaction activity?



WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(t.transaction_id) AS total_transactions,
        COALESCE(SUM(t.amount), 0) AS total_transaction_value,
        MAX(t.transaction_date) AS last_transaction_date
    FROM customers c
    LEFT JOIN accounts a
        ON a.customer_id = c.customer_id
    LEFT JOIN transactions t
        ON t.account_id = a.account_id
        AND t.status = 'Success'
    GROUP BY
        c.customer_id,
        c.customer_name
),

customer_segments AS (
    SELECT
        customer_id,
        customer_name,
        total_transactions,
        total_transaction_value,
        last_transaction_date,

        CASE
            WHEN last_transaction_date IS NULL
                OR last_transaction_date <
                   DATE_SUB(CURDATE(), INTERVAL 90 DAY)
                THEN 'Inactive'

            WHEN total_transactions >= 50
                 AND total_transaction_value >= 500000
                THEN 'High Activity'

            WHEN total_transactions >= 20
                 AND total_transaction_value >= 100000
                THEN 'Medium Activity'

            ELSE 'Low Activity'
        END AS customer_segment

    FROM customer_activity
)

SELECT
    customer_segment,
    COUNT(*) AS total_customers
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_customers DESC;


#24 What is the active customer rate?


WITH customer_activity AS (
    SELECT
        c.customer_id,
        MAX(t.transaction_date) AS last_transaction_date
    FROM customers c
    LEFT JOIN accounts a
        ON a.customer_id = c.customer_id
    LEFT JOIN transactions t
        ON t.account_id = a.account_id
        AND t.status = 'Success'
    GROUP BY c.customer_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNT(
        CASE
            WHEN last_transaction_date >=
                 DATE_SUB(CURDATE(), INTERVAL 90 DAY)
            THEN 1
        END
    ) AS active_customers,

    ROUND(
        COUNT(
            CASE
                WHEN last_transaction_date >=
                     DATE_SUB(CURDATE(), INTERVAL 90 DAY)
                THEN 1
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS active_customer_rate

FROM customer_activity;


#25  Which account types retain customers most effectively?


WITH customer_activity AS (
    SELECT
        at.account_type_id,
        at.account_type,
        c.customer_id,
        MAX(t.transaction_date) AS last_transaction_date
    FROM account_types at
    JOIN accounts a
        ON a.account_type_id = at.account_type_id
    JOIN customers c
        ON c.customer_id = a.customer_id
    LEFT JOIN transactions t
        ON t.account_id = a.account_id
        AND t.status = 'Success'
    GROUP BY
        at.account_type_id,
        at.account_type,
        c.customer_id
),

account_retention AS (
    SELECT
        account_type_id,
        account_type,
        COUNT(DISTINCT customer_id) AS total_customers,

        COUNT(DISTINCT
            CASE
                WHEN last_transaction_date >=
                     DATE_SUB(CURDATE(), INTERVAL 90 DAY)
                THEN customer_id
            END
        ) AS retained_customers

    FROM customer_activity
    GROUP BY account_type_id, account_type
)

SELECT
    account_type,
    total_customers,
    retained_customers,
    ROUND(
        retained_customers * 100.0 /
        NULLIF(total_customers, 0),
        2
    ) AS retention_rate
FROM account_retention
ORDER BY retention_rate DESC;


#26 Which cities have the highest number of customers?


SELECT
    city,
    COUNT(DISTINCT customer_id) AS total_customers
FROM customers
GROUP BY city
ORDER BY total_customers DESC;


