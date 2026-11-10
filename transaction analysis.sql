#27 Which transaction type is used most frequently?


SELECT
    tt.transaction_type_id,
    tt.transaction_type,
    COUNT(t.transaction_id) AS total_transactions
FROM transaction_types tt
JOIN transactions t
    ON t.transaction_type_id = tt.transaction_type_id
GROUP BY
    tt.transaction_type_id,
    tt.transaction_type
ORDER BY total_transactions DESC
LIMIT 1;


#28 Which transaction channel has the highest average transaction amount?

SELECT
    channel,
    ROUND(AVG(amount), 2) AS average_transaction_amount
FROM transactions
WHERE status = 'Success'
GROUP BY channel
ORDER BY average_transaction_amount DESC
LIMIT 1;

#29 What percentage of transactions failed?


SELECT
    COUNT(*) AS total_transactions,

    COUNT(
        CASE
            WHEN status = 'Failed' THEN 1
        END
    ) AS failed_transactions,

    ROUND(
        COUNT(CASE WHEN status = 'Failed' THEN 1 END)
        * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS failure_percentage

FROM transactions;


#30 What is the success rate of each transaction channel?


SELECT
    channel,

    COUNT(*) AS total_transactions,

    COUNT(
        CASE
            WHEN status = 'Success' THEN 1
        END
    ) AS successful_transactions,

    ROUND(
        COUNT(CASE WHEN status = 'Success' THEN 1 END)
        * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS success_percentage

FROM transactions
GROUP BY channel
ORDER BY success_percentage DESC;


#31 Which transaction types are used most frequently each month?


WITH monthly_transaction_count AS (
    SELECT
        YEAR(t.transaction_date) AS transaction_year,
        MONTH(t.transaction_date) AS transaction_month,
        tt.transaction_type,
        COUNT(t.transaction_id) AS total_transactions

    FROM transactions t
    JOIN transaction_types tt
        ON t.transaction_type_id = tt.transaction_type_id

    GROUP BY
        YEAR(t.transaction_date),
        MONTH(t.transaction_date),
        tt.transaction_type
),

monthly_ranking AS (
    SELECT
        transaction_year,
        transaction_month,
        transaction_type,
        total_transactions,

        RANK() OVER (
            PARTITION BY transaction_year, transaction_month
            ORDER BY total_transactions DESC
        ) AS transaction_rank

    FROM monthly_transaction_count
)

SELECT
    transaction_year,
    transaction_month,
    transaction_type,
    total_transactions

FROM monthly_ranking
WHERE transaction_rank = 1
ORDER BY transaction_year, transaction_month;


#32 Which transactions have unusually high amounts compared with their account's average transaction amount?
 
WITH account_average AS (
    SELECT
        account_id,
        AVG(amount) AS average_transaction_amount
    FROM transactions
    WHERE status = 'Success'
    GROUP BY account_id
)

SELECT
    t.transaction_id,
    t.account_id,
    t.transaction_date,
    t.amount AS transaction_amount,
    ROUND(aa.average_transaction_amount, 2)
        AS average_transaction_amount,

    ROUND(
        t.amount / aa.average_transaction_amount,
        2
    ) AS average_multiple

FROM transactions t

JOIN account_average aa
    ON t.account_id = aa.account_id

WHERE t.status = 'Success'
  AND t.amount > aa.average_transaction_amount * 3

ORDER BY t.amount DESC;


#33 During which days does transaction activity peak?



SELECT
    DAYNAME(transaction_date) AS transaction_day,
    COUNT(*) AS total_transactions
FROM transactions
WHERE status = 'Success'
GROUP BY DAYOFWEEK(transaction_date), DAYNAME(transaction_date)
ORDER BY total_transactions DESC;

#34 Which customers made three or more transactions within 10 minutes?

WITH customer_transactions AS (
    SELECT
        c.customer_id,
        c.customer_name,
        t.transaction_id,
        t.transaction_date

    FROM customers c

    JOIN accounts a
        ON c.customer_id = a.customer_id

    JOIN transactions t
        ON a.account_id = t.account_id

    WHERE t.status = 'Success'
),

rapid_transactions AS (
    SELECT
        t1.customer_id,
        t1.customer_name,
        t1.transaction_id,
        t1.transaction_date,

        COUNT(t2.transaction_id) AS transaction_count

    FROM customer_transactions t1

    JOIN customer_transactions t2
        ON t1.customer_id = t2.customer_id
        AND t2.transaction_date >= t1.transaction_date
        AND t2.transaction_date <=
            DATE_ADD(t1.transaction_date, INTERVAL 10 MINUTE)

    GROUP BY
        t1.customer_id,
        t1.customer_name,
        t1.transaction_id,
        t1.transaction_date

    HAVING COUNT(t2.transaction_id) >= 3
)

SELECT DISTINCT
    customer_id,
    customer_name

FROM rapid_transactions
ORDER BY customer_id;


#35 How do transaction values compare between weekdays and weekends?


SELECT
    CASE
        WHEN DAYOFWEEK(transaction_date) IN (1, 7)
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_category,

    COUNT(*) AS total_transactions,

    ROUND(SUM(amount), 2) AS total_transaction_value,

    ROUND(AVG(amount), 2) AS average_transaction_value

FROM transactions
WHERE status = 'Success'

GROUP BY day_category
ORDER BY total_transaction_value DESC;


#36 What is the percentage distribution of transactions by status?
SELECT
    CASE
        WHEN DAYOFWEEK(transaction_date) IN (1, 7)
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_category,

    COUNT(*) AS total_transactions,

    ROUND(SUM(amount), 2) AS total_transaction_value,

    ROUND(AVG(amount), 2) AS average_transaction_value

FROM transactions
WHERE status = 'Success'

GROUP BY day_category
ORDER BY total_transaction_value DESC;


#36 
SELECT
    status,

    COUNT(*) AS total_transactions,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_distribution

FROM transactions

GROUP BY status

ORDER BY percentage_distribution DESC;


#37 Which transaction channels have the highest total transaction value?



SELECT
    channel,

    COUNT(transaction_id) AS total_transactions,

    ROUND(SUM(amount), 2) AS total_transaction_value

FROM transactions

WHERE status = 'Success'

GROUP BY channel

ORDER BY total_transaction_value DESC;


#38 What is the average transaction value across all branches?


SELECT
    b.branch_id,
    b.branch_name,

    COUNT(t.transaction_id) AS total_transactions,

    ROUND(AVG(t.amount), 2) AS average_transaction_value

FROM branches b

JOIN accounts a
    ON b.branch_id = a.branch_id

JOIN transactions t
    ON a.account_id = t.account_id

WHERE t.status = 'Success'

GROUP BY
    b.branch_id,
    b.branch_name

ORDER BY average_transaction_value DESC;

#39 Which transactions have the highest individual amounts?


SELECT
    t.transaction_id,
    c.customer_id,
    c.customer_name,
    a.account_id,
    t.transaction_date,
    t.channel,
    t.amount AS transaction_amount

FROM transactions t

JOIN accounts a
    ON t.account_id = a.account_id

JOIN customers c
    ON a.customer_id = c.customer_id

WHERE t.status = 'Success'

ORDER BY t.amount DESC

LIMIT 10;


#40 What is the total value and count of successful transactions by transaction type?


SELECT
    tt.transaction_type,

    COUNT(t.transaction_id) AS successful_transaction_count,

    ROUND(SUM(t.amount), 2) AS total_transaction_value

FROM transactions t

JOIN transaction_types tt
    ON t.transaction_type_id = tt.transaction_type_id

WHERE t.status = 'Success'

GROUP BY tt.transaction_type

ORDER BY total_transaction_value DESC;


#41 Which transaction types or channels have unusually high failure rates?

SELECT
    tt.transaction_type,

    COUNT(t.transaction_id) AS total_transactions,

    COUNT(
        CASE
            WHEN t.status = 'Failed' THEN 1
        END
    ) AS failed_transactions,

    ROUND(
        COUNT(CASE WHEN t.status = 'Failed' THEN 1 END)
        * 100.0 / NULLIF(COUNT(t.transaction_id), 0),
        2
    ) AS failure_percentage

FROM transactions t

JOIN transaction_types tt
    ON t.transaction_type_id = tt.transaction_type_id

GROUP BY tt.transaction_type

HAVING failure_percentage > 10

ORDER BY failure_percentage DESC;

#42 