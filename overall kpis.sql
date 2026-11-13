#63 What is the total number of customers?

SELECT
    COUNT(DISTINCT customer_id) AS total_customers
FROM customers;

#64 What is the total number of accounts?

SELECT
    COUNT(DISTINCT account_id) AS total_accounts
FROM accounts;

#65. What is the total successful transaction value across the bank?

SELECT
    SUM(amount) AS total_successful_transaction_value
FROM transactions
WHERE status = 'Success';

#66. What is the average transaction amount across all channels?


SELECT
    AVG(amount) AS average_transaction_amount
FROM transactions
WHERE status = 'Success';

#67 What is the overall transaction failure rate?


SELECT
    COUNT(*) AS total_transactions,

    COUNT(
        CASE
            WHEN status = 'Failed' THEN 1
        END
    ) AS failed_transactions,

    ROUND(
        COUNT(
            CASE
                WHEN status = 'Failed' THEN 1
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS failure_rate_percentage

FROM transactions;

#68. What percentage of customers are active?


WITH customer_activity AS (
    SELECT
        c.customer_id,
        MAX(t.transaction_date) AS last_transaction_date
    FROM customers c
    LEFT JOIN accounts a
        ON c.customer_id = a.customer_id
    LEFT JOIN transactions t
        ON a.account_id = t.account_id
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
    ) AS active_customer_percentage

FROM customer_activity;

#69. What is the total outstanding loan portfolio?

WITH payment_summary AS (
    SELECT
        loan_id,
        SUM(payment_amount) AS total_paid
    FROM loan_payments
    WHERE payment_status = 'Paid'
    GROUP BY loan_id
)

SELECT
    SUM(
        l.loan_amount - COALESCE(ps.total_paid, 0)
    ) AS total_outstanding_loan_portfolio

FROM loans l
LEFT JOIN payment_summary ps
    ON l.loan_id = ps.loan_id;

#70 What percentage of total transaction value does each branch contribute?

WITH branch_transactions AS (
    SELECT
        b.branch_id,
        b.branch_name,
        SUM(t.amount) AS branch_transaction_value
    FROM branches b
    INNER JOIN accounts a
        ON b.branch_id = a.branch_id
    INNER JOIN transactions t
        ON a.account_id = t.account_id
    WHERE t.status = 'Success'
    GROUP BY
        b.branch_id,
        b.branch_name
)

SELECT
    branch_id,
    branch_name,
    branch_transaction_value,

    ROUND(
        branch_transaction_value * 100.0 /
        NULLIF(SUM(branch_transaction_value) OVER(), 0),
        2
    ) AS contribution_percentage

FROM branch_transactions
ORDER BY contribution_percentage DESC;


#71 What is the overall loan default rate?


SELECT
    COUNT(*) AS total_loans,

    COUNT(
        CASE
            WHEN loan_status = 'Defaulted' THEN 1
        END
    ) AS defaulted_loans,

    ROUND(
        COUNT(
            CASE
                WHEN loan_status = 'Defaulted' THEN 1
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS loan_default_rate_percentage

FROM loans;

#72 How does monthly transaction value change across the bank?


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
        monthly_transaction_value - previous_month_value,
        2
    ) AS value_change,

    ROUND(
        (monthly_transaction_value - previous_month_value)
        * 100.0 / NULLIF(previous_month_value, 0),
        2
    ) AS growth_percentage

FROM monthly_comparison
ORDER BY transaction_year, transaction_month;
