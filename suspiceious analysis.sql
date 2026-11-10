
#1 Identify high-value transactions above ₹2,00,000.

SELECT
    t.transaction_id,
    c.customer_id,
    c.customer_name,
    a.account_id,
    t.transaction_date,
    t.amount,
    tt.transaction_type,
    t.channel,
    t.status
FROM transactions t
INNER JOIN accounts a
    ON t.account_id = a.account_id
INNER JOIN customers c
    ON a.customer_id = c.customer_id
INNER JOIN transaction_types tt
    ON t.transaction_type_id = tt.transaction_type_id
WHERE t.amount > 200000
ORDER BY t.amount DESC;

#2 Find rapid repeated transactions within five minutes.

SELECT
    t1.account_id,
    t1.transaction_id AS first_transaction_id,
    t1.transaction_date AS first_transaction_time,
    COUNT(t2.transaction_id) AS transactions_within_5_minutes
FROM transactions t1
INNER JOIN transactions t2
    ON t1.account_id = t2.account_id
    AND t2.transaction_date >= t1.transaction_date
    AND t2.transaction_date <=
        DATE_ADD(t1.transaction_date, INTERVAL 5 MINUTE)
GROUP BY
    t1.account_id,
    t1.transaction_id,
    t1.transaction_date
HAVING COUNT(t2.transaction_id) >= 3
ORDER BY
    transactions_within_5_minutes DESC,
    first_transaction_time;

#3 Flag sudden increases compared with the previous transaction.


WITH transaction_comparison AS (
    SELECT
        transaction_id,
        account_id,
        transaction_date,
        amount,

        LAG(amount) OVER (
            PARTITION BY account_id
            ORDER BY transaction_date, transaction_id
        ) AS previous_transaction_amount

    FROM transactions
    WHERE status = 'Success'
)

SELECT
    transaction_id,
    account_id,
    transaction_date,
    previous_transaction_amount,
    amount AS current_transaction_amount,

    ROUND(
        amount / NULLIF(previous_transaction_amount, 0),
        2
    ) AS increase_ratio,

    CASE
        WHEN previous_transaction_amount IS NULL
            THEN 'No Previous Transaction'

        WHEN amount > previous_transaction_amount * 3
            THEN 'Suspicious Increase'

        ELSE 'Normal'
    END AS transaction_flag

FROM transaction_comparison
ORDER BY account_id, transaction_date;


#4 Identify accounts with repeated failed transactions.


SELECT
    a.account_id,
    c.customer_id,
    c.customer_name,
    COUNT(t.transaction_id) AS total_failed_transactions
FROM accounts a
INNER JOIN customers c
    ON a.customer_id = c.customer_id
INNER JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.status = 'Failed'
GROUP BY
    a.account_id,
    c.customer_id,
    c.customer_name
HAVING COUNT(t.transaction_id) >= 3
ORDER BY total_failed_transactions DESC;

#5 Identify unusual overnight transactions.


SELECT
    t.transaction_id,
    c.customer_id,
    c.customer_name,
    t.account_id,
    t.transaction_date,
    TIME(t.transaction_date) AS transaction_time,
    t.amount,
    t.channel,
    t.status

FROM transactions t

INNER JOIN accounts a
    ON t.account_id = a.account_id

INNER JOIN customers c
    ON a.customer_id = c.customer_id

WHERE TIME(t.transaction_date) >= '00:00:00'
  AND TIME(t.transaction_date) < '05:00:00'
  AND t.status = 'Success'

ORDER BY t.transaction_date;

#6 Compare transaction amounts with the customer's historical average.


WITH customer_history AS (
    SELECT
        a.customer_id,
        AVG(t.amount) AS historical_avg_amount
    FROM transactions t
    INNER JOIN accounts a
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
    GROUP BY a.customer_id
)

SELECT
    t.transaction_id,
    c.customer_id,
    c.customer_name,
    t.account_id,
    t.transaction_date,
    t.amount AS current_transaction_amount,
    ROUND(ch.historical_avg_amount, 2)
        AS historical_avg_amount,

    ROUND(
        t.amount / NULLIF(ch.historical_avg_amount, 0),
        2
    ) AS average_increase_ratio,

    CASE
        WHEN t.amount > ch.historical_avg_amount * 3
            THEN 'Unusual Transaction'
        ELSE 'Normal Transaction'
    END AS transaction_flag

FROM transactions t

INNER JOIN accounts a
    ON t.account_id = a.account_id

INNER JOIN customers c
    ON a.customer_id = c.customer_id

INNER JOIN customer_history ch
    ON c.customer_id = ch.customer_id

WHERE t.status = 'Success'

ORDER BY average_increase_ratio DESC;


#7 
WITH customer_history AS (
    SELECT
        a.customer_id,
        AVG(t.amount) AS historical_avg_amount
    FROM transactions t
    INNER JOIN accounts a
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
    GROUP BY a.customer_id
)

SELECT
    t.transaction_id,
    c.customer_id,
    c.customer_name,
    t.account_id,
    t.transaction_date,
    t.amount AS current_transaction_amount,
    ROUND(ch.historical_avg_amount, 2)
        AS historical_avg_amount,

    ROUND(
        t.amount / NULLIF(ch.historical_avg_amount, 0),
        2
    ) AS average_increase_ratio,

    CASE
        WHEN t.amount > ch.historical_avg_amount * 3
            THEN 'Unusual Transaction'
        ELSE 'Normal Transaction'
    END AS transaction_flag

FROM transactions t

INNER JOIN accounts a
    ON t.account_id = a.account_id

INNER JOIN customers c
    ON a.customer_id = c.customer_id

INNER JOIN customer_history ch
    ON c.customer_id = ch.customer_id

WHERE t.status = 'Success'

ORDER BY average_increase_ratio DESC;
