#!/bin/bash

# Wait for PostgreSQL to be ready
until pg_isready -U postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

# Create user, database, and tables
psql -v ON_ERROR_STOP=1 --username "postgres" <<-EOSQL
    -- Create a new user
    CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';

    -- Grant the user permission to create databases
    ALTER USER ${DB_USER} CREATEDB;

    -- Create a new database owned by the new user
    CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};

    -- Connect to the new database and create a table
    \c ${DB_NAME};

    CREATE TABLE users (
        name TEXT,
        date_of_birth DATE
    );

    CREATE TABLE accounts (
        account_name TEXT PRIMARY KEY,
        account_type TEXT NOT NULL,
        asset BOOLEAN NOT NULL,
        created_date DATE NOT NULL,
        initial_balance DECIMAL(10, 2) NOT NULL
    );

    CREATE TABLE account_balances (
        account_name TEXT REFERENCES accounts (account_name) ON DELETE CASCADE,
        snapshot_date DATE NOT NULL,
        account_balance DECIMAL(10, 2) NOT NULL
    );

    CREATE TABLE categories (
        category_name TEXT PRIMARY KEY
    );

    CREATE TABLE subcategories (
        subcategory_name TEXT PRIMARY KEY
    );

    CREATE TABLE transactions (
        transaction_id UUID PRIMARY KEY,
        transaction_date DATE NOT NULL,
        merchant TEXT NOT NULL,
        bucket TEXT NOT NULL,
        amount DECIMAL(10, 2) NOT NULL,
        category TEXT REFERENCES categories (category_name) ON DELETE SET NULL,
        subcategory TEXT REFERENCES subcategories (subcategory_name) ON DELETE SET NULL,
        account_name TEXT REFERENCES accounts (account_name) ON DELETE CASCADE,
        is_recurring BOOLEAN NOT NULL
    );

    CREATE TABLE recurring_transactions (
        recurring_transaction_id UUID PRIMARY KEY,
        frequency TEXT NOT NULL,
        merchant TEXT NOT NULL,
        amount DECIMAL(10, 2),
        last_occurrence DATE NOT NULL,
        next_occurrence DATE NOT NULL
    );

    CREATE TABLE budget (
        budget_month TEXT NOT NULL,
        budget_year TEXT NOT NULL,
        budget_category TEXT REFERENCES categories (category_name) ON DELETE CASCADE,
        budget_subcategory TEXT REFERENCES subcategories (subcategory_name) ON DELETE CASCADE,
        budget_amount DECIMAL(10, 2) NOT NULL
    );

    CREATE TABLE goals (
        goal_id UUID PRIMARY KEY,
        goal_name TEXT NOT NULL,
        goal_description TEXT,
        goal_amount DECIMAL(10, 2) NOT NULL,
        goal_date DATE NOT NULL,
        goal_accounts TEXT NOT NULL
    );

    CREATE TABLE retirement_inputs (
        plan_id UUID PRIMARY KEY,
        withdrawal_rate DECIMAL(2, 1) NOT NULL,
        average_return DECIMAL(4, 2) NOT NULL,
        average_variance DECIMAL(4, 2) NOT NULL,
        retirement_date DATE NOT NULL,
        inflation_rate DECIMAL(2, 1) NOT NULL,
        income_growth_rate DECIMAL(4, 2) NOT NULL,
        yearly_expenses DECIMAL(10, 2) NOT NULL
    );

    CREATE TABLE retirement_simulations (
        simulation_id SERIAL PRIMARY KEY,
        plan_id UUID REFERENCES retirement_inputs (plan_id) ON DELETE CASCADE,
        simulation_date DATE NOT NULL,
        user_age INT NOT NULL,
        starting_balance DECIMAL(14, 2) NOT NULL,
        total_withdrawals DECIMAL(14, 2) NOT NULL,
        total_contributions DECIMAL(14, 2) NOT NULL,
        one_time_expenses DECIMAL(14, 2) NOT NULL,
        return_rate DECIMAL(4, 2) NOT NULL,
        total_returns DECIMAL(14, 2) NOT NULL,
        ending_balance DECIMAL(14, 2) NOT NULL
    );
EOSQL
