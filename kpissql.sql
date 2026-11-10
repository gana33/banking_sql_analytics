#Which loan type has the highest default rate?

SELECT
    loan_type,
    COUNT(*) AS total_loans,
    SUM(
        CASE
            WHEN loan_status = 'Default' THEN 1
            ELSE 0
        END
    ) AS defaulted_loans,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN loan_status = 'Default' THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_percentage
FROM loans
GROUP BY loan_type
ORDER BY default_rate_percentage DESC
LIMIT 1;
