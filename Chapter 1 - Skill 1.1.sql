---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 1 - Manage Data with Transact-SQL
-- Skill 1.1: Create Transact-SQL SELECT queries
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice SQL environment and Sample databases
---------------------------------------------------------------------

-- Database server:
-- The code samples in this book can be executed in SQL Server 2016 Service Pack 1 (SP1) or later
-- and Azure SQL Database.
-- If you prefer to work with a local instance, SQL Server Developer
-- Edition is free if you sign up for the free Visual Studio Dev
-- Essentials program: https://myprodscussu1.app.vssubscriptions.visualstudio.com/Downloads?q=SQL%20Server%20Developer
-- In the installation's Feature Selection step, you need to choose only the Database Engine Services feature.

-- SQL Server Management Studio:
-- Download and install SQL Server Management Studio from here: https://msdn.microsoft.com/en-us/library/mt238290.aspx

-- Sample database:
-- This book uses the TSQLV4 sample database.
-- It is supported in both SQL Server 2016 and Azure SQL Database.
-- Download and install TSQLV4 from here: http://tsql.solidq.com/SampleDatabases/TSQLV4.zip

---------------------------------------------------------------------
-- Further reading
---------------------------------------------------------------------

-- If you are looking for further reading for more practice and 
-- more advanced topics beyond this book, see:
-- TSQL Fundamentals, 3rd Edition for more practice of fundamentals: https://www.microsoftpressstore.com/store/t-sql-fundamentals-9781509302000
-- T-SQL Querying for more advanced querying and query tuning: https://www.microsoftpressstore.com/store/t-sql-querying-9780735685048?w_ptgrevartcl=T-SQL+Querying_2193978
-- Itzik Ben-Gan's column in SQL Server Pro: http://sqlmag.com/author/itzik-ben-gan

---------------------------------------------------------------------
-- Understanding the Foundations of T-SQL
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Using T-SQL in a Relational Way
---------------------------------------------------------------------

USE TSQLV4;

SELECT country
FROM HR.Employees;

SELECT DISTINCT country
FROM HR.Employees;

SELECT empid, lastname
FROM HR.Employees;

SELECT empid, lastname
FROM HR.Employees
ORDER BY empid;

SELECT empid, lastname
FROM HR.Employees
ORDER BY 1;

SELECT empid, firstname + ' ' + lastname
FROM HR.Employees;

SELECT empid, firstname + ' ' + lastname AS fullname
FROM HR.Employees;

---------------------------------------------------------------------
-- Logical Query Processing
---------------------------------------------------------------------

---------------------------------------------------------------------
-- T-SQL as a Declarative English-Like Language
---------------------------------------------------------------------

SELECT shipperid, phone, companyname
FROM Sales.Shippers;

---------------------------------------------------------------------
-- Logical Query Processing Phases
---------------------------------------------------------------------

SELECT country, YEAR(hiredate) AS yearhired, COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20140101'
GROUP BY country, YEAR(hiredate)
HAVING COUNT(*) > 1
ORDER BY country, yearhired DESC;

-- fails
SELECT country, YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE yearhired >= 2014;

-- fails
SELECT empid, country, YEAR(hiredate) AS yearhired, yearhired - 1 AS prevyear
FROM HR.Employees;

---------------------------------------------------------------------
-- Getting started with the SELECT statement
---------------------------------------------------------------------

---------------------------------------------------------------------
-- The FROM clause
---------------------------------------------------------------------

-- basic example
SELECT empid, firstname, lastname, country
FROM HR.Employees;

-- assigning a table alias
SELECT E.empid, firstname, lastname, country
FROM HR.Employees AS E;

---------------------------------------------------------------------
-- The SELECT clause
---------------------------------------------------------------------

-- projection of a subset of the source attributes
SELECT empid, firstname, lastname
FROM HR.Employees;

-- bug due to missing comma
SELECT empid, firstname lastname
FROM HR.Employees;

-- aliasing for renaming
SELECT empid AS employeeid, firstname, lastname
FROM HR.Employees;

-- expression without an alias
SELECT empid, firstname + N' ' + lastname
FROM HR.Employees;

-- aliasing expressions
SELECT empid, firstname + N' ' + lastname AS fullname
FROM HR.Employees;

-- removing duplicates with DISTINCT
SELECT DISTINCT country, region, city
FROM HR.Employees;

-- SELECT without FROM
SELECT 10 AS col1, 'ABC' AS col2;

---------------------------------------------------------------------
-- Filtering data with predicates
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Predicates and three-valued-logic
---------------------------------------------------------------------

-- content of Employees table
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees;

-- employees from the United States
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE country = N'USA';

-- employees from Washington State
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region = N'WA';

-- employees that are not from Washington State
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA';

-- handling NULLs incorrectly
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA'
   OR region = NULL;

-- employees that are not from Washington State, resolving the NULL problem
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA'
   OR region IS NULL;

---------------------------------------------------------------------
-- Filtering character data
---------------------------------------------------------------------

-- regular character string
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = 'Davis';

-- Unicode character string
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'Davis';

-- employees whose last name starts with the letter D.
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';

---------------------------------------------------------------------
-- Filtering date and time data
---------------------------------------------------------------------

-- language-dependent literal
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '02/12/16';

-- language-neutral literal
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '20160212';

-- create table Sales.Orders2
DROP TABLE IF EXISTS Sales.Orders2;

SELECT orderid, CAST(orderdate AS DATETIME) AS orderdate, empid, custid
INTO Sales.Orders2 
FROM Sales.Orders;

-- filtering a range, the unrecommended way
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders2
WHERE orderdate BETWEEN '20160401' AND '20160430 23:59:59.999';

-- filtering a range, the recommended way
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders2
WHERE orderdate >= '20160401' AND orderdate < '20160501';

---------------------------------------------------------------------
-- Sorting data
---------------------------------------------------------------------

-- query with no ORDER BY doesn't guarantee presentation ordering
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA';

-- simple ORDER BY example
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city;

-- use descending order
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city DESC;

-- order by multiple columns
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city, empid;

-- order by ordinals (bad practice)
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;

-- change SELECT list but forget to change ordinals in ORDER BY
SELECT empid, city, firstname, lastname, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;

-- order by elements not in SELECT
SELECT empid, city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthdate;

-- when DISTINCT specified, can only order by elements in SELECT

-- following fails
SELECT DISTINCT city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthdate;

-- following succeeds
SELECT DISTINCT city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city;

-- can refer to column aliases asigned in SELECT
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthmonth;

-- NULLs sort first
SELECT orderid, shippeddate
FROM Sales.Orders
WHERE custid = 20
ORDER BY shippeddate;

---------------------------------------------------------------------
-- Filtering data with TOP and OFFSET-FETCH
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Filtering Data with TOP
---------------------------------------------------------------------

-- return the three most recent orders
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- can use percent
SELECT TOP (1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
GO

-- can use expression, like parameter or variable, as input
DECLARE @n AS BIGINT = 5;

SELECT TOP (@n) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
GO

-- no ORDER BY, ordering is arbitrary
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders;

-- be explicit about arbitrary ordering
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL);

-- non-deterministic ordering even with ORDER BY since ordering isn't unique
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- return all ties
SELECT TOP (3) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- break ties
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;

---------------------------------------------------------------------
-- Filtering Data with OFFSET-FETCH
---------------------------------------------------------------------

-- skip 50 rows, fetch next 25 rows
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;

-- fetch first 25 rows
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 0 ROWS FETCH FIRST 25 ROWS ONLY;

-- skip 50 rows, return all the rest
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS;

-- ORDER BY is mandatory; return some 3 rows
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL)
OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY;
GO

-- can use expressions as input
DECLARE @pagesize AS BIGINT = 25, @pagenum AS BIGINT = 3;

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;
GO

-- For more on TOP and OFFSET-FETCH, including optimization, see
-- T-SQL Querying book's sample chapter: Chapter 5 - TOP and OFFSET-FETCH
-- You can find the online version of this chapter here: https://www.microsoftpressstore.com/articles/article.aspx?p=2314819
-- You can download the PDF version of this chapter here: https://ptgmedia.pearsoncmg.com/images/9780735685048/samplepages/9780735685048.pdf
-- This chapter uses the sample database TSQLV3 which you can download here: http://tsql.solidq.com/SampleDatabases/TSQLV3.zip

---------------------------------------------------------------------
-- Combining sets with set operators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- UNION and UNION ALL
---------------------------------------------------------------------

-- locations that are employee locations or customer locations or both
SELECT country, region, city
FROM HR.Employees

UNION

SELECT country, region, city
FROM Sales.Customers;

-- with UNION ALL duplicates are not discarded
SELECT country, region, city
FROM HR.Employees

UNION ALL

SELECT country, region, city
FROM Sales.Customers;

---------------------------------------------------------------------
-- INTERSECT
---------------------------------------------------------------------

-- locations that are both employee and customer locations
SELECT country, region, city
FROM HR.Employees

INTERSECT

SELECT country, region, city
FROM Sales.Customers;

---------------------------------------------------------------------
-- EXCEPT
---------------------------------------------------------------------

-- locations that are employee locations but not customer locations
SELECT country, region, city
FROM HR.Employees

EXCEPT

SELECT country, region, city
FROM Sales.Customers;

-- cleanup
DROP TABLE IF EXISTS Sales.Orders2;
