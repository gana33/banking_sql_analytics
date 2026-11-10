#42 Which account type has the highest number of accounts?

SELECT
    at.account_type,
    COUNT(a.account_id) AS total_accounts

FROM accounts a

JOIN account_types at
    ON a.account_type_id = at.account_type_id

GROUP BY
    at.account_type

ORDER BY total_accounts DESC

LIMIT 1;

#43 What is the dormant account rate?

WITH account_activity AS (
    SELECT
        a.account_id,
        a.account_status,
        MAX(
            CASE
                WHEN t.status = 'Success'
                THEN t.transaction_date
            END
        ) AS last_transaction_date

    FROM accounts a

    LEFT JOIN transactions t
        ON a.account_id = t.account_id

    GROUP BY
        a.account_id,
        a.account_status
),

dormant_accounts AS (
    SELECT
        account_id,

        CASE
            WHEN last_transaction_date IS NULL
                OR last_transaction_date < DATE_SUB(CURDATE(), INTERVAL 90 DAY)
            THEN 1
            ELSE 0
        END AS dormant_flag

    FROM account_activity
)

SELECT
    COUNT(*) AS total_accounts,

    SUM(dormant_flag) AS dormant_accounts,

    ROUND(
        SUM(dormant_flag) * 100.0 /
        NULLIF(COUNT(*), 0),
        2
    ) AS dormant_account_percentage

FROM dormant_accounts;

#44 Which accounts have had no transactions during the last 90 days of the dataset?


WITH dataset_period AS (
    SELECT
        MAX(transaction_date) AS latest_transaction_date
    FROM transactions
),

inactive_accounts AS (
    SELECT
        a.account_id,
        a.account_status,
        dp.latest_transaction_date

    FROM accounts a

    CROSS JOIN dataset_period dp

    LEFT JOIN transactions t
        ON a.account_id = t.account_id
        AND t.transaction_date >
            DATE_SUB(dp.latest_transaction_date, INTERVAL 90 DAY)
        AND t.transaction_date <= dp.latest_transaction_date

    WHERE t.transaction_id IS NULL
)

SELECT *
FROM inactive_accounts
ORDER BY account_id;


#45 What is the distribution of accounts by account status?


SELECT
    account_status,

    COUNT(account_id) AS total_accounts,

    ROUND(
        COUNT(account_id) * 100.0 /
        SUM(COUNT(account_id)) OVER (),
        2
    ) AS percentage_distribution

FROM accounts

GROUP BY account_status

ORDER BY percentage_distribution DESC;


#46 Which account types have the highest average initial balance?


SELECT
    at.account_type,

    COUNT(a.account_id) AS total_accounts,

    ROUND(AVG(a.initial_balance), 2)
        AS average_initial_balance

FROM accounts a

JOIN account_types at
    ON a.account_type_id = at.account_type_id

GROUP BY at.account_type

ORDER BY average_initial_balance DESC;

#47 How many customers have only one account compared with customers who have multiple accounts?


WITH customer_account_count AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(a.account_id) AS total_accounts

    FROM customers c

    LEFT JOIN accounts a
        ON c.customer_id = a.customer_id

    GROUP BY
        c.customer_id,
        c.customer_name
),

customer_segments AS (
    SELECT
        customer_id,

        CASE
            WHEN total_accounts = 1
                THEN 'Single Account Customer'

            WHEN total_accounts > 1
                THEN 'Multiple Account Customer'

            ELSE 'No Account'
        END AS account_category

    FROM customer_account_count
)

SELECT
    account_category,
    COUNT(customer_id) AS total_customers

FROM customer_segments

GROUP BY account_category

ORDER BY total_customers DESC;

#48