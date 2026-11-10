CREATE DATABASE banking;
 use banking
#BRANCHES
CREATE TABLE branches (
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    branch_type VARCHAR(30) NOT NULL,
    opened_date DATE NOT NULL
);

#ACCOUN TYPE
CREATE TABLE account_types (
    account_type_id VARCHAR(10) PRIMARY KEY,
    account_type VARCHAR(50) NOT NULL UNIQUE,
    interest_rate DECIMAL(5,2) NOT NULL,
    minimum_balance DECIMAL(12,2) NOT NULL
);


CREATE TABLE transaction_types (
    transaction_type_id VARCHAR(10) PRIMARY KEY,
    transaction_type VARCHAR(50) NOT NULL UNIQUE,
    direction VARCHAR(10) NOT NULL
);




CREATE TABLE customers (
    customer_id VARCHAR(15) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10),
    date_of_birth DATE,
    city VARCHAR(50),
    occupation VARCHAR(50),
    customer_segment VARCHAR(30),
    join_date DATE NOT NULL
);


CREATE TABLE accounts (
    account_id VARCHAR(15) PRIMARY KEY,

    customer_id VARCHAR(15) NOT NULL,

    branch_id VARCHAR(10) NOT NULL,

    account_type_id VARCHAR(10) NOT NULL,

    open_date DATE NOT NULL,

    account_status VARCHAR(20) NOT NULL,

    initial_balance DECIMAL(15,2) NOT NULL,

    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_accounts_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id),

    CONSTRAINT fk_accounts_type
        FOREIGN KEY (account_type_id)
        REFERENCES account_types(account_type_id)
);



CREATE TABLE transactions (
    transaction_id VARCHAR(20) PRIMARY KEY,

    account_id VARCHAR(15) NOT NULL,

    transaction_type_id VARCHAR(10) NOT NULL,

    transaction_date DATETIME NOT NULL,

    amount DECIMAL(15,2) NOT NULL,

    channel VARCHAR(30) NOT NULL,

    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_transactions_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id),

    CONSTRAINT fk_transactions_type
        FOREIGN KEY (transaction_type_id)
        REFERENCES transaction_types(transaction_type_id)
);



CREATE TABLE loans (
    loan_id VARCHAR(15) PRIMARY KEY,

    customer_id VARCHAR(15) NOT NULL,

    branch_id VARCHAR(10) NOT NULL,

    loan_type VARCHAR(30) NOT NULL,

    loan_amount DECIMAL(15,2) NOT NULL,

    interest_rate DECIMAL(5,2) NOT NULL,

    loan_start_date DATE NOT NULL,

    tenure_months INT NOT NULL,

    loan_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_loans_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_loans_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
);


CREATE TABLE loan_payments (
    payment_id VARCHAR(20) PRIMARY KEY,

    loan_id VARCHAR(15) NOT NULL,

    payment_date DATE NOT NULL,

    payment_amount DECIMAL(15,2) NOT NULL,

    payment_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_payments_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
);
