#1 hightest transaction value
SELECT
    b.branch_id,
    b.branch_name,
    SUM(t.amount) AS total_transaction_value
FROM branches b
JOIN accounts a
    ON b.branch_id = a.branch_id
JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.status = 'Success'
GROUP BY
    b.branch_id,
    b.branch_name
ORDER BY total_transaction_value DESC
LIMIT 1;

#2 hightest susccesful transaction value
SELECT
    b.branch_id,
    b.branch_name,
    COUNT(t.transaction_id) AS successful_transaction_count
FROM branches b
JOIN accounts a
    ON b.branch_id = a.branch_id
JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.status = 'Success'
GROUP BY
    b.branch_id,
    b.branch_name
ORDER BY successful_transaction_count DESC
LIMIT 1;


#3 month wiese trnscation value for each branches

SELECT
    YEAR(t.transaction_date) AS year,
    MONTH(t.transaction_date) AS month,
    SUM(t.amount) AS monthly_value, b.branch_id,b.city
FROM transactions t
join accounts a on a.account_id=t.account_id
join branches b on b.branch_id=a.branch_id
GROUP BY
    YEAR(t.transaction_date),
    MONTH(t.transaction_date),b.branch_id,b.city
ORDER BY
    year,
    month 
    
    
#4 Which branches experienced a decrease in transaction value compared with the previous month? ✅


WITH monthly_transactions AS (
    SELECT
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date) AS transaction_year,
        MONTH(t.transaction_date) AS transaction_month,
        SUM(t.amount) AS transaction_value
    FROM branches b
    JOIN accounts a
        ON b.branch_id = a.branch_id
    JOIN transactions t
        ON a.account_id = t.account_id
    WHERE t.status = 'Success'
    GROUP BY
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date),
        MONTH(t.transaction_date)
),
monthly_comparison AS (
    SELECT
        branch_id,
        branch_name,
        transaction_year,
        transaction_month,
        transaction_value,
        LAG(transaction_value) OVER (
            PARTITION BY branch_id
            ORDER BY transaction_year, transaction_month
        ) AS previous_month_value
    FROM monthly_transactions
)
SELECT
    branch_id,
    branch_name,
    transaction_year,
    transaction_month,
    previous_month_value,
    transaction_value,
    previous_month_value - transaction_value AS decrease_amount
FROM monthly_comparison
WHERE transaction_value < previous_month_value
ORDER BY decrease_amount DESC;


#5
with avg_tran as ( 
select b.branch_id, sum(t.amount) as  average_amount from transactions t
join accounts a on a.account_id=t.account_id
join branches b on b.branch_id=a.branch_id
group by b.branch_id
  )
select branch_id, average_amount from avg_tran
where average_amount>( select avg(average_amount) from avg_tran ) order by average_amount desc 
 
 #6
 WITH branch_transaction_values AS (
    SELECT
        b.branch_id,
        b.branch_name,
        b.state,
        SUM(t.amount) AS total_transaction_value
    FROM branches b
    JOIN accounts a
        ON b.branch_id = a.branch_id
    JOIN transactions t
        ON a.account_id = t.account_id
    WHERE t.status = 'Success'
    GROUP BY
        b.branch_id,
        b.branch_name,
        b.state
)
SELECT
    branch_id,
    branch_name,
    state,
    total_transaction_value,
    RANK() OVER (
        PARTITION BY state
        ORDER BY total_transaction_value DESC
    ) AS branch_rank
FROM branch_transaction_values
ORDER BY state, branch_rank;


#8
WITH monthly_transactions AS (
    SELECT
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date) AS transaction_year,
        MONTH(t.transaction_date) AS transaction_month,
        SUM(t.amount) AS monthly_transaction_value
    FROM branches b
    JOIN accounts a
        ON b.branch_id = a.branch_id
    JOIN transactions t
        ON a.account_id = t.account_id
    WHERE t.status = 'Success'
    GROUP BY
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date),
        MONTH(t.transaction_date)
)
SELECT
    branch_id,
    branch_name,
    transaction_year,
    transaction_month,
    monthly_transaction_value,
    SUM(monthly_transaction_value) OVER (
        PARTITION BY branch_id
        ORDER BY transaction_year, transaction_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_transaction_value
FROM monthly_transactions
ORDER BY
    branch_name,
    transaction_year,
    transaction_month;

#8
with runing_total as (select year(t.transaction_date) as transcation_year,b.branch_id, b.branch_name,sum(t.amount) as transcation_amount from branches b
join accounts a 
   on a.branch_id=b.branch_id
join  transactions t  
    on a.account_id=t.account_id
group by b.branch_id,b.branch_name,year(t.transaction_date)
)
select branch_id, branch_name,transcation_year, sum(transcation_amount) over
 (partition by branch_id order by transcation_year
 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as culmativesum from runing_total
 order by branch_id, branch_name,transcation_year


#9
with month_analysis as (select month(t.transaction_date) as months,year(transaction_date) as years,
sum(t.amount) as total_amounts,b.branch_id,b.branch_name,b.city
 from  branches b
join accounts a on a.branch_id=b.branch_id
join transactions t on t.account_id=a.account_id
where t.status='success'
group by  month(t.transaction_date), year(transaction_date),b.branch_id,b.branch_name,b.city),
branch_ranking as(select *,rank() over 
(partition by years,months order by total_amounts desc ) as branch_rank
from month_analysis)
select branch_id,branch_name,months,years,total_amounts ,branch_rank 
from branch_ranking 
where branch_rank=1
order by  total_amounts desc

#10
select b.branch_id,b.branch_name,b.city,count(distinct c.customer_id ) as total_count from branches b
join accounts a on a.branch_id=b.branch_id
join customers c on c.customer_id=a.customer_id
where a.account_status='active'
group by b.branch_id,b.branch_name
order by total_count desc






#11
WITH branch_transactions AS (
    SELECT
        b.branch_id,
        b.branch_name,
        SUM(t.amount) AS total_amount
    FROM branches b
    JOIN accounts a
        ON a.branch_id = b.branch_id
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
      AND t.transaction_date >= '2026-01-01'
      AND t.transaction_date < '2027-01-01'
    GROUP BY b.branch_id, b.branch_name
),

branch_acquisition AS (
    SELECT
        a.branch_id,
        COUNT(DISTINCT c.customer_id) AS new_customer
    FROM accounts a
    JOIN customers c
        ON c.customer_id = a.customer_id
    WHERE c.join_date >= '2026-01-01'
      AND c.join_date < '2027-01-01'
      AND a.open_date >= '2026-01-01'
      AND a.open_date < '2027-01-01'
    GROUP BY a.branch_id
)

SELECT
    bt.branch_id,
    bt.branch_name,
    bt.total_amount,
    COALESCE(ba.new_customer, 0) AS new_customers
FROM branch_transactions bt
LEFT JOIN branch_acquisition ba
    ON bt.branch_id = ba.branch_id
ORDER BY bt.total_amount DESC;


#13 Calculate month-over-month transaction growth percentage for each branch


WITH monthly_transactions AS (
    SELECT
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date) AS transaction_year,
        MONTH(t.transaction_date) AS transaction_month,
        SUM(t.amount) AS total_amount
    FROM branches b
    JOIN accounts a
        ON a.branch_id = b.branch_id
    JOIN transactions t
        ON t.account_id = a.account_id
    WHERE t.status = 'Success'
    GROUP BY
        b.branch_id,
        b.branch_name,
        YEAR(t.transaction_date),
        MONTH(t.transaction_date)
),

monthly_growth AS (
    SELECT
        branch_id,
        branch_name,
        transaction_year,
        transaction_month,
        total_amount,

        LAG(total_amount) OVER (
            PARTITION BY branch_id
            ORDER BY transaction_year, transaction_month
        ) AS previous_month_amount

    FROM monthly_transactions
)

SELECT
    branch_id,
    branch_name,
    transaction_year,
    transaction_month,
    total_amount,
    previous_month_amount,

    ROUND(
        (total_amount - previous_month_amount)
        / NULLIF(previous_month_amount, 0) * 100,
        2
    ) AS growth_percentage

FROM monthly_growth
ORDER BY branch_id, transaction_year, transaction_month;
