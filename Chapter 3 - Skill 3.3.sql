---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 3 - Program databases by using Transact-SQL
-- Skill 3.3: Implement data types and NULLs
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Working with data types
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Choosing the appropriate data type
---------------------------------------------------------------------

DECLARE @f AS FLOAT = 29545428.022495;
SELECT CAST(@f AS NUMERIC(28, 14)) AS numericvalue;

---------------------------------------------------------------------
-- Data type conversions
---------------------------------------------------------------------

SELECT CAST(1 AS BIT);

SELECT CAST(4000000000 AS BIGINT);
GO

SELECT CAST('abc' AS INT);
GO

SELECT TRY_CAST('abc' AS INT);

SELECT CONVERT(DATE, '1/2/2017', 101);

SELECT PARSE('1/2/2017' AS DATE USING 'en-US');

SELECT 1 + '1';

SELECT 5 / 2;

SELECT
  CAST(10.999 AS NUMERIC(12, 0)) AS numeric_to_numeric,
  CAST(10.999 AS INT) AS numeric_to_int;
GO

DECLARE
  @s AS CHAR(21) = '20170212 23:59:59.999',
  @dt2 AS DATETIME2 = '20170212 23:59:59.999999';

SELECT
  CAST(@s AS DATETIME) AS char_to_datetime,
  CAST(@dt2 AS DATETIME) AS char_to_datetime;

---------------------------------------------------------------------
-- Handling NULLs
---------------------------------------------------------------------

---------------------------------------------------------------------
-- The ISNULL and COALESCE functions
---------------------------------------------------------------------

-- simple examples
SET NOCOUNT ON;
USE TSQLV4;

DECLARE
  @x AS INT = NULL,
  @y AS INT = 1759,
  @z AS INT = 42;

SELECT COALESCE(@x, @y, @z);
SELECT ISNULL(@x, @y);
GO

-- datatype of result
DECLARE
  @x AS VARCHAR(3) = NULL,
  @y AS VARCHAR(10) = '1234567890';

SELECT ISNULL(@x, @y) AS ISNULLxy, COALESCE(@x, @y) AS COALESCExy;
GO

SELECT ISNULL('1a2b', 1234) AS ISNULLstrnum;
GO
SELECT COALESCE('1a2b', 1234) AS COALESCEstrnum;
GO

-- nullability of result
DROP TABLE IF EXISTS dbo.TestNULLs;
GO
SELECT empid,
  ISNULL(region, country) AS ISNULLregioncountry,
  COALESCE(region, country) AS COALESCEregioncountry
INTO dbo.TestNULLs
FROM HR.Employees;

SELECT
  COLUMNPROPERTY(OBJECT_ID('dbo.TestNULLs'), 'ISNULLregioncountry',
    'AllowsNull') AS ISNULLregioncountry,
  COLUMNPROPERTY(OBJECT_ID('dbo.TestNULLs'), 'COALESCEregioncountry',
    'AllowsNull') AS COALESCEregioncountry;

DROP TABLE IF EXISTS dbo.TestNULLs;
GO

---------------------------------------------------------------------
-- Handling NULLs when combining data from multiple tables
---------------------------------------------------------------------

-- sample data
DROP TABLE IF EXISTS dbo.TableA, dbo.TableB;
GO
CREATE TABLE dbo.TableA
(
  key1 CHAR(1) NOT NULL,
  key2 CHAR(1) NULL,
  A_val VARCHAR(10) NOT NULL,
  CONSTRAINT UNQ_TableA_key1_key2 UNIQUE CLUSTERED (key1, key2)
);

INSERT INTO dbo.TableA(key1, key2, A_val)
  VALUES('w', 'w', 'A w w'),
        ('x', 'y', 'A x y'),
        ('x', NULL, 'A x NULL');

CREATE TABLE dbo.TableB
(
  key1 CHAR(1) NOT NULL,
  key2 CHAR(1) NULL,
  B_val VARCHAR(10) NOT NULL,
  CONSTRAINT UNQ_TableB_key1_key2 UNIQUE CLUSTERED (key1, key2)
);

INSERT INTO dbo.TableB(key1, key2, B_val)
  VALUES('x', 'y', 'B x y'),
        ('x', NULL, 'B x NULL'),
        ('z', 'z', 'B z z');
GO

-- using joins

-- without special NULL handling
SELECT A.A_val, B.B_val
FROM dbo.TableA AS A
  INNER JOIN dbo.TableB AS B
    ON A.key1 = B.key1
    AND A.key2 = B.key2;

-- with special NULL handling, allowing efficient use of indexing
SELECT A.A_val, B.B_val
FROM dbo.TableA AS A
  INNER JOIN dbo.TableB AS B
    ON A.key1 = B.key1
    AND (A.key2 = B.key2 OR A.key2 IS NULL AND B.key2 IS NULL);

-- using COALESCE, prevents ability to rely on index order
SELECT A.A_val, B.B_val
FROM dbo.TableA AS A
  INNER JOIN dbo.TableB AS B
    ON A.key1 = B.key1
    AND COALESCE(A.key2, '<N/A>') = COALESCE(B.key2, '<N/A>');

-- using subqueries, similar handling to joins, only can return values from only one side

-- without special NULL handling
SELECT A.A_val
FROM dbo.TableA AS A
WHERE EXISTS
  ( SELECT * FROM dbo.TableB AS B
    WHERE A.key1 = B.key1
      AND A.key2 = B.key2 );

-- with special NULL handling, allowing efficient use of indexing
SELECT A.A_val
FROM dbo.TableA AS A
WHERE EXISTS
  ( SELECT * FROM dbo.TableB AS B
    WHERE A.key1 = B.key1
      AND (A.key2 = B.key2 OR A.key2 IS NULL AND B.key2 IS NULL) );

-- using COALESCE, prevents ability to rely on index order
SELECT A.A_val
FROM dbo.TableA AS A
WHERE EXISTS
  ( SELECT * FROM dbo.TableB AS B
    WHERE A.key1 = B.key1
    AND COALESCE(A.key2, '<N/A>') = COALESCE(B.key2, '<N/A>') );

-- using set operators, distinctness-based comparison, can't return additional columns
SELECT key1, key2 FROM dbo.TableA
INTERSECT
SELECT key1, key2 FROM dbo.TableB;

-- combining joins, subqueries and set operators
SELECT A.A_val, B.B_val
FROM dbo.TableA AS A
  INNER JOIN dbo.TableB AS B
    ON EXISTS( SELECT A.key1, A.key2
               INTERSECT
               SELECT B.key1, B.key2 );

-- cleanup
DROP TABLE IF EXISTS dbo.TableA, dbo.TableB;

---------------------------------------------------------------------
-- Further reading
---------------------------------------------------------------------

-- If you are looking for further reading for more practice and 
-- more advanced topics beyond this book, see:
-- TSQL Fundamentals 3rd Edition for more practice of fundamentals: https://www.microsoftpressstore.com/store/t-sql-fundamentals-9781509302000
-- T-SQL Querying for more advanced querying and query tuning: https://www.microsoftpressstore.com/store/t-sql-querying-9780735685048?w_ptgrevartcl=T-SQL+Querying_2193978
