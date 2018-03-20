---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 1 - Manage Data with Transact-SQL
-- Skill 1.3: Implement functions and aggregate data
-- © Itzik Ben-Gan
---------------------------------------------------------------------

USE TSQLV4;

---------------------------------------------------------------------
-- Type conversion functions
---------------------------------------------------------------------

-- CAST
SELECT CAST('100' AS INT);

-- CONVERT
SELECT CONVERT(DATE, '01/02/2017', 101);
SELECT CONVERT(DATE, '01/02/2017', 103)

-- PARSE
SELECT PARSE('01/02/2017' AS DATE USING 'en-US');
SELECT PARSE('01/02/2017' AS DATE USING 'en-GB');

-- TRY_CAST, TRY_CONVERT, TRY_PARSE
SELECT CONVERT(DATE, '14/02/2017', 101) AS col1, CONVERT(DATE, '02/14/2017', 101) AS col2;

SELECT TRY_CONVERT(DATE, '14/02/2017', 101) AS col1, TRY_CONVERT(DATE, '02/14/2017', 101) AS col2;

-- FORMAT
SELECT FORMAT(SYSDATETIME(), 'yyyy-MM-dd');

---------------------------------------------------------------------
-- Date and time functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Current date and time
---------------------------------------------------------------------

SELECT
  GETDATE()           AS [GETDATE],
  CURRENT_TIMESTAMP   AS [CURRENT_TIMESTAMP],
  GETUTCDATE()        AS [GETUTCDATE],
  SYSDATETIME()       AS [SYSDATETIME],
  SYSUTCDATETIME()    AS [SYSUTCDATETIME],
  SYSDATETIMEOFFSET() AS [SYSDATETIMEOFFSET];

SELECT
  CAST(SYSDATETIME() AS DATE) AS [current_date],
  CAST(SYSDATETIME() AS TIME) AS [current_time];

---------------------------------------------------------------------
-- Date and time parts
---------------------------------------------------------------------

-- DATEPART
SELECT DATEPART(month, '20170212');

-- DAY, MONTH, YEAR
SELECT
  DAY('20170212') AS theday,
  MONTH('20170212') AS themonth,
  YEAR('20170212') AS theyear;

-- DATENAME
SELECT DATENAME(month, '20170212');

-- fromparts
SELECT
  DATEFROMPARTS(2017, 02, 12),
  DATETIME2FROMPARTS(2017, 02, 12, 13, 30, 5, 1, 7),
  DATETIMEFROMPARTS(2017, 02, 12, 13, 30, 5, 997),
  DATETIMEOFFSETFROMPARTS(2017, 02, 12, 13, 30, 5, 1, -8, 0, 7),
  SMALLDATETIMEFROMPARTS(2017, 02, 12, 13, 30),
  TIMEFROMPARTS(13, 30, 5, 1, 7);

-- EOMONTH
SELECT EOMONTH(SYSDATETIME());

---------------------------------------------------------------------
-- Add and diff functions
---------------------------------------------------------------------

-- DATEADD
SELECT DATEADD(year, 1, '20170212');

-- DATEDIFF, DATEDIFF_BIG
SELECT DATEDIFF(day, '20160212', '20170212');

---------------------------------------------------------------------
-- Offset related functions
---------------------------------------------------------------------

-- SWITCHOFFSET
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-05:00');
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-08:00');

-- TODATETIMEOFFSET
/*
UPDATE dbo.T1
  SET dto = TODATETIMEOFFSET(dt, theoffset);
*/

-- example with both functions
SELECT 
  SWITCHOFFSET('20170212 14:00:00.0000000 -05:00', '-08:00') AS [SWITCHOFFSET],
  TODATETIMEOFFSET('20170212 14:00:00.0000000', '-08:00') AS [TODATETIMEOFFSET];

-- AT TIME ZONE when similar to SWITCHOFFSET
SELECT SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific Standard Time';

-- AT TIME ZONE when similar to TODATETIMEOFFSET
DECLARE @dt AS DATETIME2 = '20170212 14:00:00.0000000';
SELECT @dt AT TIME ZONE 'Pacific Standard Time';

-- time zones
SELECT * FROM sys.time_zone_info;

-- two conversions
DECLARE @dt AS DATETIME2 = '20170212 14:00:00.0000000'; -- stored as UTC
SELECT @dt AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'; -- switched to Pacific Standard Time

---------------------------------------------------------------------
-- Character functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Concatenation
---------------------------------------------------------------------

-- concatenation
SELECT empid, country, region, city,
  country + N', ' + region + N', ' + city AS location
FROM HR.Employees;

-- convert NULL to empty string
SELECT empid, country, region, city,
  country + ISNULL(N', ' + region, N'' ) + N', ' + city AS location
FROM HR.Employees;

-- using CONCAT
SELECT empid, country, region, city,
  CONCAT(country, N', ' + region, N', ' + city) AS location
FROM HR.Employees;

---------------------------------------------------------------------
-- Substring extraction and position
---------------------------------------------------------------------

SELECT SUBSTRING('abcde', 1, 3); -- 'abc'

SELECT LEFT('abcde', 3); -- 'abc'

SELECT RIGHT('abcde', 3); -- 'cde'

SELECT CHARINDEX(' ','Inigo Montoya'); -- 6

SELECT PATINDEX('%[0-9]%', 'abcd123efgh'); -- 5

---------------------------------------------------------------------
-- String length
---------------------------------------------------------------------

SELECT LEN(N'xyz'); -- 3

SELECT DATALENGTH(N'xyz'); -- 6

---------------------------------------------------------------------
-- String alteration
---------------------------------------------------------------------

SELECT REPLACE('.1.2.3.', '.', '/'); -- '/1/2/3/'

SELECT REPLICATE('0', 10); -- '0000000000'

SELECT STUFF(',x,y,z', 1, 1, ''); -- 'x,y,z'

---------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------

SELECT UPPER('aBcD'); -- 'ABCD'

SELECT LOWER('aBcD'); -- 'abcd'

SELECT RTRIM(LTRIM('   xyz   ')); -- 'xyz'

SELECT FORMAT(1759, '0000000000');

SELECT FORMAT(1759, 'd10');

---------------------------------------------------------------------
-- String splitting
---------------------------------------------------------------------

DECLARE @orderids AS VARCHAR(MAX) = N'10248,10542,10731,10765,10812';

SELECT value
FROM STRING_SPLIT(@orderids, ',');
GO


DECLARE @orderids AS VARCHAR(MAX) = N'10248,10542,10731,10765,10812';

SELECT O.orderid, O.orderdate, O.custid, O.empid
FROM STRING_SPLIT(@orderids, ',') AS K
  INNER JOIN Sales.Orders AS O
    ON O.orderid = CAST(K.value AS INT);
GO

---------------------------------------------------------------------
-- CASE expression and related functions
---------------------------------------------------------------------

-- simple CASE expression
SELECT productid, productname, unitprice, discontinued,
  CASE discontinued
    WHEN 0 THEN 'No'
    WHEN 1 THEN 'Yes'
    ELSE 'Unknown'
  END AS discontinued_desc
FROM Production.Products;

-- searched CASE expression
SELECT productid, productname, unitprice,
  CASE
    WHEN unitprice < 20.00 THEN 'Low'
    WHEN unitprice < 40.00 THEN 'Medium'
    WHEN unitprice >= 40.00 THEN 'High'
    ELSE 'Unknown'
  END AS pricerange
FROM Production.Products;

-- COALESCE versus ISNULL
DECLARE
  @x AS VARCHAR(3) = NULL,
  @y AS VARCHAR(10) = '1234567890';

SELECT COALESCE(@x, @y) AS [COALESCE], ISNULL(@x, @y) AS [ISNULL];

-- for more information about COALESCE versus ISNULL see: http://sqlmag.com/t-sql/coalesce-vs-isnull

---------------------------------------------------------------------
-- System functions
---------------------------------------------------------------------

-- @@ROWCOUNT and ROWCOUNT_BIG
DECLARE @empid AS INT = 10;

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE empid = @empid;

IF @@ROWCOUNT = 0
  PRINT CONCAT('Employee ', CAST(@empid AS VARCHAR(10)), ' was not found.');

-- COMPRESS and DECOMPRESS
/*
INSERT INTO dbo.MyNotes(notes)
  VALUES(COMPRESS(@notes));

SELECT keycol
  CAST(DECOMPRESS(notes) AS NVARCHAR(MAX)) AS notes
FROM dbo.MyNotes;
*/

-- CONTEXT_INFO and SESSION_CONTEXT
DECLARE @mycontextinfo AS VARBINARY(128) = CAST('us_english' AS VARBINARY(128));
SET CONTEXT_INFO @mycontextinfo;
GO

SELECT CAST(CONTEXT_INFO() AS VARCHAR(128)) AS mycontextinfo;

EXEC sys.sp_set_session_context 
  @key = N'language', @value = 'us_english', @read_only = 1; 

SELECT SESSION_CONTEXT(N'language') AS [language];

-- GUID and identity functions
SELECT NEWID() AS myguid;

---------------------------------------------------------------------
-- Arithmetic operators and aggregate functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Arithmetic operators
---------------------------------------------------------------------

-- precedence
SELECT 2 + 3 * 2 + 10 / 2;

SELECT 2 + (3 * 2) + (10 / 2);

SELECT ((2 + 3) * 2 + 10) / 2;

SELECT 9 / 2;
GO

-- explicit conversion
DECLARE @p1 AS INT = 9, @p2 AS INT = 2;
SELECT CAST(@p1 AS NUMERIC(12, 2)) / CAST(@p2 AS NUMERIC(12, 2));
GO

DECLARE @p1 AS INT = 9, @p2 AS INT = 2;
SELECT 1.0 * @p1 / @p2;
GO

---------------------------------------------------------------------
-- Aggregate functions
---------------------------------------------------------------------

-- explicit grouped query
SELECT empid, SUM(qty) AS totalqty
FROM Sales.OrderValues
GROUP BY empid;

-- implied grouping
SELECT SUM(qty) AS totalqty FROM Sales.OrderValues;

-- integer average
SELECT AVG(qty) AS avgqty FROM Sales.OrderValues;

-- numeric average
SELECT AVG(CAST(qty AS NUMERIC(12, 2))) AS avgqty FROM Sales.OrderValues;
SELECT AVG(1.0 * qty) AS avgqty FROM Sales.OrderValues;
GO

---------------------------------------------------------------------
-- Example involving arithmetic operators and aggregate functions
---------------------------------------------------------------------

-- median
DECLARE @cnt AS INT = (SELECT COUNT(*) FROM Sales.OrderValues);

SELECT AVG(1.0 * qty) AS median
FROM ( SELECT qty
       FROM Sales.OrderValues
       ORDER BY qty
       OFFSET (@cnt - 1) / 2 ROWS FETCH NEXT 2 - @cnt % 2 ROWS ONLY ) AS D;
GO

---------------------------------------------------------------------
-- Search arguments
---------------------------------------------------------------------

-- example with date range

-- not sargable
SELECT orderid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2015;

-- sargable
SELECT orderid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20150101'
  AND orderdate < '20160101';
GO

-- example with addition

-- not sargable
DECLARE @todt AS DATE = '20151231';

SELECT orderid, orderdate
FROM Sales.Orders
WHERE DATEADD(day, -1, orderdate) < @todt;
GO

-- sargable
DECLARE @todt AS DATE = '20151231';

SELECT orderid, orderdate
FROM Sales.Orders
WHERE orderdate < DATEADD(day, 1, @todt);
GO

-- example with LEFT and LIKE

-- not sargable
SELECT empid, lastname
FROM HR.Employees
WHERE LEFT(lastname, 1) = N'D';

-- sargable
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';
GO

-- Example with NULLs

-- sargable, but doesn't handle NULLs correctly
DECLARE @dt AS DATE = '20150212'; -- also try with NULL

SELECT orderid, shippeddate
FROM Sales.Orders
WHERE shippeddate = @dt;
GO

DECLARE @dt AS DATE = NULL;

SELECT orderid, shippeddate
FROM Sales.Orders
WHERE shippeddate = @dt;
GO

-- correct, but not sargable
DECLARE @dt AS DATE = NULL;

SELECT orderid, shippeddate
FROM Sales.Orders
WHERE ISNULL(shippeddate, '99991231') = ISNULL(@dt, '99991231');
GO

-- sargable
DECLARE @dt AS DATE = NULL;

SELECT orderid, shippeddate
FROM Sales.Orders
WHERE shippeddate = @dt
   OR (shippeddate IS NULL AND @dt IS NULL);
GO

-- also sargable
DECLARE @dt AS DATE = NULL;

SELECT orderid, shippeddate
FROM Sales.Orders
WHERE EXISTS (SELECT shippeddate INTERSECT SELECT @dt);
GO

---------------------------------------------------------------------
-- Function determinism
---------------------------------------------------------------------

-- RAND
SELECT RAND(1759); -- on all machines: 0.746348756684839

SELECT RAND(); -- every execution a different result

SELECT RAND(1759);
SELECT RAND();

-- Random value from 1 to 10
SELECT 1 + ABS(CHECKSUM(NEWID())) % 10;

-- Most nondeterministic functions are invoked once per row; NEWID is an exception
SELECT empid, SYSDATETIME() AS dtnow, RAND() AS rnd, NEWID() AS newguid
FROM HR.Employees;
GO

-- Order randomly
SELECT TOP (3) empid, firstname, lastname
FROM HR.Employees
ORDER BY RAND();

SELECT TOP (3) empid, firstname, lastname
FROM HR.Employees
ORDER BY CHECKSUM(NEWID());

