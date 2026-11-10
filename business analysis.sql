#1 Confirm the monthly transaction value decline.

WITH monthly_transactions AS (
    SELECT
        YEAR(transaction_date) AS transaction_year,
        MONTH(transaction_date) AS transaction_month,
        SUM(amount) AS monthly_transaction_value
    FROM transactions
    WHERE status = 'Success'
    GROUP BY
        YEAR(transaction_date),
        MONTH(transaction_date)
),

monthly_comparison AS (
    SELECT
        transaction_year,
        transaction_month,
        monthly_transaction_value,

        LAG(monthly_transaction_value) OVER (
            ORDER BY transaction_year, transaction_month
        ) AS previous_month_value

    FROM monthly_transactions
)

SELECT
    transaction_year,
    transaction_month,
    monthly_transaction_value,
    previous_month_value,

    ROUND(
        previous_month_value - monthly_transaction_value,
        2
    ) AS decline_amount,

    ROUND(
        (previous_month_value - monthly_transaction_value)
        * 100.0 / NULLIF(previous_month_value, 0),
        2
    ) AS decline_percentage

FROM monthly_comparison

WHERE monthly_transaction_value < previous_month_value

ORDER BY transaction_year, transaction_month;

#2 Identify the branches contributing to the decline.

WITH branch_monthly AS (
    SELECT
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date) AS transaction_year,
        MONTH(t.transaction_date) AS transaction_month,
        SUM(t.amount) AS monthly_transaction_value

    FROM branches b

    INNER JOIN accounts a
        ON b.branch_id = a.branch_id

    INNER JOIN transactions t
        ON a.account_id = t.account_id

    WHERE t.status = 'Success'

    GROUP BY
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date),
        MONTH(t.transaction_date)
),

branch_comparison AS (
    SELECT
        branch_id,
        branch_name,
        transaction_year,
        transaction_month,
        monthly_transaction_value,

        LAG(monthly_transaction_value) OVER (
            PARTITION BY branch_id
            ORDER BY transaction_year, transaction_month
        ) AS previous_month_value

    FROM branch_monthly
)

SELECT
    branch_id,
    branch_name,
    transaction_year,
    transaction_month,
    previous_month_value,
    monthly_transaction_value,

    ROUND(
        previous_month_value - monthly_transaction_value,
        2
    ) AS decline_amount,

    ROUND(
        (previous_month_value - monthly_transaction_value)
        * 100.0 / NULLIF(previous_month_value, 0),
        2
    ) AS decline_percentage

FROM branch_comparison

WHERE monthly_transaction_value < previous_month_value

ORDER BY decline_amount DESC;
