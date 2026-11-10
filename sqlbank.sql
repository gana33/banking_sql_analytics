describe account_types
select count(*) from branches;
select count(*) from account_types;
select count(*) from accounts;
select count(*) from customers;
select count(*) from loan_payments;
select count(*) from loans;
select count(*) from transaction_types;
select count(*) from transactions;
select count(*) from branches;


SELECT
    a.account_id,
    c.customer_name,
    b.branch_name,
    at.account_type
FROM accounts a
JOIN customers c
    ON a.customer_id = c.customer_id
JOIN branches b
    ON a.branch_id = b.branch_id
JOIN account_types at
    ON a.account_type_id = at.account_type_id
LIMIT 10;