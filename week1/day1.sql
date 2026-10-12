-- Day 1: SQL basics on a Saviynt-style users table
-- Topics: SELECT, FROM, WHERE, IS NULL / IS NOT NULL
-- Database: SQLite (iam_practice.db)

-- 1. Everyone in the IT department
SELECT firstname, lastname, title
FROM users
WHERE departmentname = 'IT';

-- 2. Contractors only
SELECT username, employeetype
FROM users
WHERE employeetype = 'Contractor';

-- 3. Offboarded users (have a term date)
SELECT username, termdate
FROM users
WHERE termdate IS NOT NULL;

-- 4. Active users (no term date)
SELECT username, termdate
FROM users
WHERE termdate IS NULL;