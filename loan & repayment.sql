#48 Which loan type has the highest default rate?

SELECT
    loan_type,

    COUNT(loan_id) AS total_loans,

    COUNT(
        CASE
            WHEN loan_status = 'Defaulted' THEN 1
        END
    ) AS defaulted_loans,

    ROUND(
        COUNT(CASE WHEN loan_status = 'Defaulted' THEN 1 END)
        * 100.0 / NULLIF(COUNT(loan_id), 0),
        2
    ) AS default_rate_percentage

FROM loans

GROUP BY loan_type

ORDER BY default_rate_percentage DESC;


#49 What is the outstanding loan amount by branch?


SELECT
    b.branch_id,
    b.branch_name,

    COUNT(l.loan_id) AS total_active_loans,

    ROUND(SUM(l.loan_amount), 2)
        AS total_active_loan_amount

FROM branches b

JOIN loans l
    ON b.branch_id = l.branch_id

WHERE l.loan_status = 'Active'

GROUP BY
    b.branch_id,
    b.branch_name

ORDER BY total_active_loan_amount DESC;

#50 Which customers have missed loan payments?


SELECT
    c.customer_id,
    c.customer_name,

    COUNT(lp.payment_id) AS missed_payment_count,

    ROUND(SUM(lp.payment_amount), 2)
        AS total_failed_payment_amount

FROM customers c

JOIN loans l
    ON c.customer_id = l.customer_id

JOIN loan_payments lp
    ON l.loan_id = lp.loan_id

WHERE lp.payment_status = 'Failed'

GROUP BY
    c.customer_id,
    c.customer_name

HAVING COUNT(lp.payment_id) >= 1

ORDER BY missed_payment_count DESC;

#51 Which loan types generate the highest total loan value?


SELECT
    loan_type,

    COUNT(loan_id) AS total_loans,

    ROUND(SUM(loan_amount), 2) AS total_loan_value,

    ROUND(AVG(loan_amount), 2) AS average_loan_amount

FROM loans

GROUP BY loan_type

ORDER BY total_loan_value DESC;

#52. Which branches have the highest outstanding loan balances?


WITH branch_loan_amount AS (
    SELECT
        branch_id,
        SUM(loan_amount) AS total_loan_amount

    FROM loans

    GROUP BY branch_id
),

loan_repayments AS (
    SELECT
        l.branch_id,

        SUM(
            CASE
                WHEN lp.payment_status = 'Success'
                THEN lp.payment_amount
                ELSE 0
            END
        ) AS total_repaid_amount

    FROM loans l

    LEFT JOIN loan_payments lp
        ON l.loan_id = lp.loan_id

    GROUP BY l.branch_id
)

SELECT
    b.branch_id,
    b.branch_name,

    ROUND(bla.total_loan_amount, 2)
        AS total_loan_amount,

    ROUND(COALESCE(lr.total_repaid_amount, 0), 2)
        AS total_repaid_amount,

    ROUND(
        bla.total_loan_amount -
        COALESCE(lr.total_repaid_amount, 0),
        2
    ) AS outstanding_loan_balance

FROM branch_loan_amount bla

JOIN branches b
    ON bla.branch_id = b.branch_id

JOIN loan_repayments lr
    ON bla.branch_id = lr.branch_id

ORDER BY outstanding_loan_balance DESC;


#53. Which loan categories have the highest delinquency rates?


SELECT
    l.loan_type,

    COUNT(lp.payment_id) AS total_payments,

    COUNT(
        CASE
            WHEN lp.payment_status = 'Late' THEN 1
        END
    ) AS late_payments,

    ROUND(
        COUNT(CASE WHEN lp.payment_status = 'Late' THEN 1 END)
        * 100.0 / NULLIF(COUNT(lp.payment_id), 0),
        2
    ) AS delinquency_rate

FROM loans l

JOIN loan_payments lp
    ON l.loan_id = lp.loan_id

GROUP BY l.loan_type

ORDER BY delinquency_rate DESC;

#54. What percentage of scheduled loan payments have been repaid?


SELECT
    COUNT(payment_id) AS total_scheduled_payments,

    COUNT(
        CASE
            WHEN payment_status = 'Paid' THEN 1
        END
    ) AS successful_payments,

    ROUND(
        COUNT(
            CASE
                WHEN payment_status = 'Paid' THEN 1
            END
        ) * 100.0 /
        NULLIF(COUNT(payment_id), 0),
        2
    ) AS repayment_percentage

FROM loan_payments;

#55 What is the total loan portfolio by loan type?

SELECT
    loan_type,

    COUNT(loan_id) AS total_loans,

    ROUND(SUM(loan_amount), 2)
        AS total_loan_portfolio,

    ROUND(AVG(loan_amount), 2)
        AS average_loan_amount

FROM loans

GROUP BY loan_type

ORDER BY total_loan_portfolio DESC;


#56 What is the loan repayment rate?


SELECT
    COUNT(payment_id) AS total_payments,

    COUNT(
        CASE
            WHEN payment_status = 'Paid' THEN 1
        END
    ) AS paid_payments,

    ROUND(
        COUNT(
            CASE
                WHEN payment_status = 'Paid' THEN 1
            END
        ) * 100.0 /
        NULLIF(COUNT(payment_id), 0),
        2
    ) AS loan_repayment_rate

FROM loan_payments;


#57 Which customers have the highest total loan amounts?


SELECT
    c.customer_id,
    c.customer_name,

    COUNT(l.loan_id) AS total_loans,

    ROUND(SUM(l.loan_amount), 2)
        AS total_loan_amount

FROM customers c

JOIN loans l
    ON c.customer_id = l.customer_id

GROUP BY
    c.customer_id,
    c.customer_name

ORDER BY total_loan_amount DESC

LIMIT 10;

#58 What is the average loan amount by loan type?


SELECT
    loan_type,

    COUNT(loan_id) AS total_loans,

    ROUND(AVG(loan_amount), 2)
        AS average_loan_amount,

    ROUND(SUM(loan_amount), 2)
        AS total_loan_amount

FROM loans

GROUP BY loan_type

ORDER BY average_loan_amount DESC;

#59 How many loans are active, closed or defaulted?


SELECT
    loan_status,

    COUNT(loan_id) AS total_loans,

    ROUND(
        COUNT(loan_id) * 100.0 /
        NULLIF(SUM(COUNT(loan_id)) OVER (), 0),
        2
    ) AS percentage_distribution

FROM loans

GROUP BY loan_status

ORDER BY total_loans DESC;

#60. Which branches have the highest number of loans? 


SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    COUNT(l.loan_id) AS total_loans
FROM branches b
INNER JOIN loans l
    ON b.branch_id = l.branch_id
GROUP BY
    b.branch_id,
    b.branch_name,
    b.city
ORDER BY total_loans DESC
LIMIT 10;

#61 What is the total amount of loan payments received by month?


SELECT
    YEAR(payment_date) AS payment_year,
    MONTH(payment_date) AS payment_month,
    SUM(payment_amount) AS total_payment_received
FROM loan_payments
WHERE payment_status = 'Paid'
GROUP BY
    YEAR(payment_date),
    MONTH(payment_date)
ORDER BY
    payment_year,
    payment_month;

#62 Which loan types have the highest outstanding balances?


WITH loan_summary AS (
    SELECT
        loan_id,
        loan_type,
        loan_amount
    FROM loans
),

payment_summary AS (
    SELECT
        loan_id,
        SUM(payment_amount) AS total_paid
    FROM loan_payments
    WHERE payment_status = 'Paid'
    GROUP BY loan_id
)

SELECT
    ls.loan_type,
    SUM(ls.loan_amount) AS total_loan_amount,
    SUM(COALESCE(ps.total_paid, 0)) AS total_paid_amount,
    SUM(
        ls.loan_amount - COALESCE(ps.total_paid, 0)
    ) AS outstanding_balance
FROM loan_summary ls
LEFT JOIN payment_summary ps
    ON ls.loan_id = ps.loan_id
GROUP BY ls.loan_type
ORDER BY outstanding_balance DESC;
