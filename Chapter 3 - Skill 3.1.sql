---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 3 - Program databases by using Transact-SQL
-- Skill 3.1: Create database programmability objects by using Transact-SQL
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Views
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Working with views 
---------------------------------------------------------------------

-- definition of Sales.OrderTotals view
-- the view computes total order quantities and net values
USE TSQLV4;
GO
CREATE OR ALTER VIEW Sales.OrderTotals
  WITH SCHEMABINDING
AS

SELECT
  O.orderid, O.custid, O.empid, O.shipperid,  O.orderdate,
  O.requireddate, O.shippeddate,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
       AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  O.orderid, O.custid, O.empid, O.shipperid, O.orderdate,
  O.requireddate, O.shippeddate;
GO

-- query view
SELECT orderid, orderdate, custid, empid, val
FROM Sales.OrderTotals;

-- see plan in Figure 3-1 showing access to original tables

-- equivalent query
SELECT
  O.orderid, O.orderdate, O.custid, O.empid,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
       AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  O.orderid, O.custid, O.empid, O.shipperid, O.orderdate,
  O.requireddate, O.shippeddate;

-- get view definition
PRINT OBJECT_DEFINITION(OBJECT_ID(N'Sales.OrderTotals'));
GO

-- a view can be defined based on a CTE
CREATE OR ALTER VIEW Sales.CustLast5OrderDates
  WITH SCHEMABINDING
AS

WITH C AS
(
  SELECT
    custid, orderdate,
    DENSE_RANK() OVER(PARTITION BY custid ORDER BY orderdate DESC) AS pos
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3], [4], [5]
FROM C
  PIVOT(MAX(orderdate) FOR pos IN ([1], [2], [3], [4], [5])) AS P;
GO

-- query view
SELECT custid, [1], [2], [3], [4], [5]
FROM Sales.CustLast5OrderDates;
GO

-- a view can even be defined based on multiple CTEs
CREATE OR ALTER VIEW Sales.CustTop5OrderValues
  WITH SCHEMABINDING
AS

WITH C1 AS
(
  SELECT
    O.orderid, O.custid,
    CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
         AS NUMERIC(12, 2)) AS val
  FROM Sales.Orders AS O
    INNER JOIN Sales.OrderDetails AS OD
      ON O.orderid = OD.orderid
  GROUP BY
    O.orderid, O.custid
),
C2 AS
(
  SELECT
    custid, val,
    ROW_NUMBER() OVER(PARTITION BY custid ORDER BY val DESC, orderid DESC) AS pos
  FROM C1
)
SELECT custid, [1], [2], [3], [4], [5]
FROM C2
  PIVOT(MAX(val) FOR pos IN ([1], [2], [3], [4], [5])) AS P;
GO

-- query view
SELECT custid, [1], [2], [3], [4], [5]
FROM Sales.CustTop5OrderValues;
GO

-- another example with joining results of aggregates at different levels
CREATE OR ALTER VIEW Sales.OrderValuePcts
  WITH SCHEMABINDING
AS

WITH OrderTotals AS
(
  SELECT
    O.orderid, O.custid,
    SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS val
  FROM Sales.Orders AS O
    INNER JOIN Sales.OrderDetails AS OD
      ON O.orderid = OD.orderid
  GROUP BY
    O.orderid, O.custid
),
GrandTotal AS
(
  SELECT SUM(val) AS grandtotalval FROM OrderTotals
),
CustomerTotals AS
(
  SELECT custid, SUM(val) AS custtotalval
  FROM OrderTotals
  GROUP BY custid
)
SELECT
  O.orderid, O.custid,
  CAST(O.val AS NUMERIC(12, 2)) AS val,
  CAST(O.val / G.grandtotalval * 100.0 AS NUMERIC(5, 2)) AS pctall,
  CAST(O.val / C.custtotalval * 100.0 AS NUMERIC(5, 2)) AS pctcust
FROM OrderTotals AS O
  CROSS JOIN GrandTotal AS G
  INNER JOIN CustomerTotals AS C
    ON O.custid = C.custid;
GO

-- query view
SELECT orderid, custid, val, pctall, pctcust
FROM Sales.OrderValuePcts;
GO

-- alternative
CREATE OR ALTER VIEW Sales.OrderValuePcts
  WITH SCHEMABINDING
AS

WITH OrderTotals AS
(
  SELECT
    O.orderid, O.custid,
    CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS NUMERIC(12, 2)) AS val
  FROM Sales.Orders AS O
    INNER JOIN Sales.OrderDetails AS OD
      ON O.orderid = OD.orderid
  GROUP BY
    O.orderid, O.custid
)
SELECT
  orderid, custid, val,
  CAST(val / SUM(val) OVER() * 100.0 AS NUMERIC(5, 2)) AS pctall,
  CAST(val / SUM(val) OVER(PARTITION BY custid) * 100.0 AS NUMERIC(5, 2)) AS pctcust
FROM OrderTotals;
GO

-- Provide access only to filtered portion
CREATE OR ALTER VIEW Sales.USACusts
  WITH SCHEMABINDING
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

---------------------------------------------------------------------
-- View attributes
---------------------------------------------------------------------

-- SCHEMABINDING

-- without SCHEMABINDING you're allowed to alter table definition
CREATE OR ALTER VIEW Sales.USACusts
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

-- alter table
BEGIN TRAN;
  ALTER TABLE Sales.Customers DROP COLUMN address;
ROLLBACK TRAN; -- undo change
GO

-- with SCHEMABINDING
CREATE OR ALTER VIEW Sales.USACusts
  WITH SCHEMABINDING
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

-- try to alter the underlying table (fails)
ALTER TABLE Sales.Customers DROP COLUMN address;
GO

-- ENCRYPTION 

-- without ENCRYPTION can get object deinition
SELECT OBJECT_DEFINITION(OBJECT_ID(N'Sales.USACusts'));
GO

-- ENCRYPTION (remember to repeat SCHEMABINDING)
CREATE OR ALTER VIEW Sales.USACusts
  WITH SCHEMABINDING, ENCRYPTION
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

-- try to get object definition; returns NULL
SELECT OBJECT_DEFINITION(OBJECT_ID(N'Sales.USACusts'));
GO

---------------------------------------------------------------------
-- Modifying data through views
---------------------------------------------------------------------

-- use following view in modification examples
CREATE OR ALTER VIEW Sales.USACusts
  WITH SCHEMABINDING
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

-- can modify data through view
INSERT INTO Sales.USACusts(
  companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax)
VALUES(
  N'Customer AAAAA', N'Contact AAAAA', N'Title AAAAA', N'Address AAAAA',
  N'Redmond', N'WA', N'11111', N'USA', N'111-1111111', N'111-1111111');

SELECT custid, companyname, country
FROM Sales.Customers
WHERE custid = SCOPE_IDENTITY();

-- without CHECK option can add/update data that doesn't satisfy WHERE filter

-- WITH CHECK OPTION
INSERT INTO Sales.USACusts(
  companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax)
VALUES(
  N'Customer BBBBB', N'Contact BBBBB', N'Title BBBBB', N'Address BBBBB',
  N'London', NULL, N'22222', N'UK', N'222-2222222', N'222-2222222');

-- can't find customer in view
SELECT custid, companyname, country
FROM Sales.USACusts
WHERE custid = SCOPE_IDENTITY();

-- can find customer in table
SELECT custid, companyname, country
FROM Sales.Customers
WHERE custid = SCOPE_IDENTITY();
GO

-- add CHECK OPTION
CREATE OR ALTER VIEW Sales.USACusts
  WITH SCHEMABINDING
AS

SELECT
  custid, companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
WITH CHECK OPTION;
GO

-- try to add row with non-US country (fails)
INSERT INTO Sales.USACusts(
  companyname, contactname, contacttitle, address,
  city, region, postalcode, country, phone, fax)
VALUES(
  N'Customer CCCCC', N'Contact CCCCC', N'Title CCCCC', N'Address CCCCC',
  N'London', NULL, N'33333', N'UK', N'333-3333333', N'333-3333333');
GO

---------------------------------------------------------------------
-- Indexed views
---------------------------------------------------------------------

-- recall OrderTotals view
CREATE OR ALTER VIEW Sales.OrderTotals
  WITH SCHEMABINDING
AS

SELECT
  O.orderid, O.custid, O.empid, O.shipperid,  O.orderdate,
  O.requireddate, O.shippeddate,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
       AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  O.orderid, O.custid, O.empid, O.shipperid, O.orderdate,
  O.requireddate, O.shippeddate;
GO

-- try to create index clustered index on view (fails)
CREATE UNIQUE CLUSTERED INDEX idx_cl_orderid ON Sales.OrderTotals(orderid);
GO

-- add COUNT_BIG
CREATE OR ALTER VIEW Sales.OrderTotals
  WITH SCHEMABINDING
AS

SELECT
  O.orderid, O.custid, O.empid, O.shipperid,  O.orderdate,
  O.requireddate, O.shippeddate,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
       AS NUMERIC(12, 2)) AS val,
  COUNT_BIG(*) AS numorderlines
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  O.orderid, O.custid, O.empid, O.shipperid, O.orderdate,
  O.requireddate, O.shippeddate;
GO

-- try to create index (fails)
CREATE UNIQUE CLUSTERED INDEX idx_cl_orderid ON Sales.OrderTotals(orderid);
GO

-- remove CAST expression
CREATE OR ALTER VIEW Sales.OrderTotals
  WITH SCHEMABINDING
AS

SELECT
  O.orderid, O.custid, O.empid, O.shipperid,  O.orderdate,
  O.requireddate, O.shippeddate,
  SUM(OD.qty) AS qty,
  SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS val,
  COUNT_BIG(*) AS numorderlines
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  O.orderid, O.custid, O.empid, O.shipperid, O.orderdate,
  O.requireddate, O.shippeddate;
GO

-- succeeds
CREATE UNIQUE CLUSTERED INDEX idx_cl_orderid ON Sales.OrderTotals(orderid);
GO

-- can now create additional nonclustered indexes
CREATE NONCLUSTERED INDEX idx_nc_custid      ON Sales.OrderTotals(custid);
CREATE NONCLUSTERED INDEX idx_nc_empid       ON Sales.OrderTotals(empid);
CREATE NONCLUSTERED INDEX idx_nc_shipperid   ON Sales.OrderTotals(shipperid);
CREATE NONCLUSTERED INDEX idx_nc_orderdate   ON Sales.OrderTotals(orderdate);
CREATE NONCLUSTERED INDEX idx_nc_shippeddate ON Sales.OrderTotals(shippeddate);

-- query view and look at query plan in Figure 3-2
SELECT orderid, custid, empid, shipperid, orderdate,
  requireddate, shippeddate, qty, val, numorderlines
FROM Sales.OrderTotals;

-- if not Enterprise edition use NOEXPAND
SELECT orderid, custid, empid, shipperid, orderdate,
  requireddate, shippeddate, qty, val, numorderlines
FROM Sales.OrderTotals WITH (NOEXPAND);

-- uses index even when querying the underlying tables (see plan in Figure 3-3)
SELECT
  O.orderid, O.custid, O.empid, O.shipperid,  O.orderdate,
  O.requireddate, O.shippeddate,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
       AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  O.orderid, O.custid, O.empid, O.shipperid, O.orderdate,
  O.requireddate, O.shippeddate;
GO

-- could create view with different name without CAST, and view with original name with CAST on top of it
CREATE OR ALTER VIEW Sales.VOrderTotals
  WITH SCHEMABINDING
AS

SELECT
  O.orderid, O.custid, O.empid, O.shipperid,  O.orderdate,
  O.requireddate, O.shippeddate,
  SUM(OD.qty) AS qty,
  SUM(OD.qty * OD.unitprice * (1 - OD.discount)) AS val,
  COUNT_BIG(*) AS numorderlines
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  O.orderid, O.custid, O.empid, O.shipperid, O.orderdate,
  O.requireddate, O.shippeddate;
GO

-- create indexes on view
CREATE UNIQUE CLUSTERED INDEX idx_cl_orderid ON Sales.VOrderTotals(orderid);
CREATE NONCLUSTERED INDEX idx_nc_custid      ON Sales.VOrderTotals(custid);
CREATE NONCLUSTERED INDEX idx_nc_empid       ON Sales.VOrderTotals(empid);
CREATE NONCLUSTERED INDEX idx_nc_shipperid   ON Sales.VOrderTotals(shipperid);
CREATE NONCLUSTERED INDEX idx_nc_orderdate   ON Sales.VOrderTotals(orderdate);
CREATE NONCLUSTERED INDEX idx_nc_shippeddate ON Sales.VOrderTotals(shippeddate);
GO

-- create view with CAST
CREATE OR ALTER VIEW Sales.OrderTotals
  WITH SCHEMABINDING
AS

SELECT
  orderid, custid, empid, shipperid,  orderdate, requireddate, shippeddate, qty,
  CAST(val AS NUMERIC(12, 2)) AS val
FROM Sales.VOrderTotals;
GO

-- Query view (see plan in Figure 3-4)
SELECT orderid, custid, empid, shipperid,  orderdate,
  requireddate, shippeddate, qty, val
FROM Sales.OrderTotals;
GO

-- Cleanup
DROP VIEW IF EXISTS
  Sales.OrderTotals, Sales.VOrderTotals, Sales.CustLast5OrderDates,
  Sales.CustTop5OrderValues, Sales.OrderValuePcts, Sales.USACusts;
GO

---------------------------------------------------------------------
-- User-defined functions
---------------------------------------------------------------------

-- Employees table
SET NOCOUNT ON;
USE TSQLV4;
DROP TABLE IF EXISTS dbo.Employees;
GO
CREATE TABLE dbo.Employees
(
  empid   INT         NOT NULL CONSTRAINT PK_Employees PRIMARY KEY,
  mgrid   INT         NULL
    CONSTRAINT FK_Employees_Employees REFERENCES dbo.Employees,
  empname VARCHAR(25) NOT NULL,
  salary  MONEY       NOT NULL,
  CHECK (empid <> mgrid)
);

INSERT INTO dbo.Employees(empid, mgrid, empname, salary)
  VALUES(1, NULL, 'David', $10000.00),
        (2, 1, 'Eitan', $7000.00),
        (3, 1, 'Ina', $7500.00),
        (4, 2, 'Seraph', $5000.00),
        (5, 2, 'Jiru', $5500.00),
        (6, 2, 'Steve', $4500.00),
        (7, 3, 'Aaron', $5000.00),
        (8, 5, 'Lilach', $3500.00),
        (9, 7, 'Rita', $3000.00),
        (10, 5, 'Sean', $3000.00),
        (11, 7, 'Gabriel', $3000.00),
        (12, 9, 'Emilia' , $2000.00),
        (13, 9, 'Michael', $2000.00),
        (14, 9, 'Didi', $1500.00);

CREATE UNIQUE INDEX idx_unc_mgr_emp_i_name_sal ON dbo.Employees(mgrid, empid)
  INCLUDE(empname, salary);
GO

---------------------------------------------------------------------
-- Scalar user-defined functions
---------------------------------------------------------------------

-- function can be based on multiple statements and involve queries
CREATE OR ALTER FUNCTION dbo.SubtreeTotalSalaries(@mgr AS INT)
  RETURNS MONEY
WITH SCHEMABINDING
AS
BEGIN
  DECLARE @totalsalary AS MONEY;

  WITH EmpsCTE AS
  (
    SELECT empid, salary
    FROM dbo.Employees
    WHERE empid = @mgr

    UNION ALL

    SELECT S.empid, S.salary
    FROM EmpsCTE AS M
      INNER JOIN dbo.Employees AS S
        ON S.mgrid = M.empid
  )
  SELECT @totalsalary = SUM(salary)
  FROM EmpsCTE;

  RETURN @totalsalary;
END;
GO

-- test function
SELECT dbo.SubtreeTotalSalaries(8) AS subtreetotal;
GO

SELECT SubtreeTotalSalaries(8) AS subtreetotal;
GO

-- test function in a query
SELECT empid, mgrid, empname, salary,
  dbo.SubtreeTotalSalaries(empid) AS subtreetotal
FROM dbo.Employees;
GO

-- most built-in functions are invoked once per query; NEWID is an exception
SELECT orderid, SYSDATETIME() AS [SYSDATETIME], RAND() AS [RAND], NEWID() AS [NEWID]
FROM Sales.Orders;
GO

-- definition of function MySYSDATETIME
CREATE OR ALTER FUNCTION dbo.MySYSDATETIME() RETURNS DATETIME2
AS
BEGIN
  RETURN SYSDATETIME();
END;
GO

-- not allowed to invoke side-effecting functions
CREATE OR ALTER FUNCTION dbo.MyRAND() RETURNS FLOAT
AS
BEGIN
  RETURN RAND();
END;
GO

-- can circumvent restriction by using a view
CREATE OR ALTER VIEW dbo.VRAND
AS

SELECT RAND() AS myrand;
GO

CREATE OR ALTER FUNCTION dbo.MyRAND() RETURNS FLOAT
AS
BEGIN
  RETURN (SELECT myrand FROM dbo.VRAND);
END;
GO

-- UDF invoked per row
SELECT orderid, dbo.MySYSDATETIME() AS mysysdatetime, dbo.MyRAND() AS myrand
FROM Sales.Orders;
GO

-- create function without SCHEMBINDING
CREATE OR ALTER FUNCTION dbo.ENDOFYEAR(@dt AS DATE) RETURNS DATE
AS
BEGIN
  RETURN DATEFROMPARTS(YEAR(@dt), 12, 31);
END;
GO

-- try to create table
DROP TABLE IF EXISTS dbo.T1;
GO
CREATE TABLE dbo.T1
(
  keycol INT NOT NULL IDENTITY CONSTRAINT PK_T1 PRIMARY KEY,
  dt DATE NOT NULL,
  dtendofyear AS dbo.ENDOFYEAR(dt) PERSISTED
);
GO

-- recreate UDF with SCHEMABINDING
CREATE OR ALTER FUNCTION dbo.ENDOFYEAR(@dt AS DATE)
  RETURNS DATE
WITH SCHEMABINDING
AS
BEGIN
  RETURN DATEFROMPARTS(YEAR(@dt), 12, 31);
END;
GO

-- try again to create table
CREATE TABLE dbo.T1
(
  keycol INT NOT NULL IDENTITY CONSTRAINT PK_T1 PRIMARY KEY,
  dt DATE NOT NULL,
  dtendofyear AS dbo.ENDOFYEAR(dt) PERSISTED
);
GO

---------------------------------------------------------------------
-- Inline table-valued user-defined functions
---------------------------------------------------------------------

-- definition of function GetPage
CREATE OR ALTER FUNCTION dbo.GetPage(@pagenum AS BIGINT, @pagesize AS BIGINT)
  RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
  WITH C AS
  (
    SELECT ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum,
      orderid, orderdate, custid, empid
    FROM Sales.Orders
  )
  SELECT rownum, orderid, orderdate, custid, empid
  FROM C
  WHERE rownum BETWEEN (@pagenum - 1) * @pagesize + 1 AND @pagenum * @pagesize;
GO

-- test function
SELECT rownum, orderid, orderdate, custid, empid
FROM dbo.GetPage(3, 12) AS T;
GO

-- alternative definition of function GetPage
CREATE OR ALTER FUNCTION dbo.GetPage(@pagenum AS BIGINT, @pagesize AS BIGINT)
  RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
  SELECT ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum,
    orderid, orderdate, custid, empid
  FROM Sales.Orders
  ORDER BY orderdate, orderid
  OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;
GO

-- test function
SELECT rownum, orderid, orderdate, custid, empid
FROM dbo.GetPage(3, 12) AS T;

-- return subtree; use NULL as manager of root
DROP FUNCTION IF EXISTS dbo.GetSubtree;
GO
CREATE FUNCTION dbo.GetSubtree(@mgr AS INT, @maxlevels AS INT = NULL)
  RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
  WITH EmpsCTE AS
  (
    SELECT empid, CAST(NULL AS INT) AS mgrid, empname, salary, 0 as lvl,
      CAST('.' AS VARCHAR(900)) AS sortpath
    FROM dbo.Employees
    WHERE empid = @mgr

    UNION ALL

    SELECT S.empid, S.mgrid, S.empname, S.salary, M.lvl + 1 AS lvl,
      CAST(M.sortpath + CAST(S.empid AS VARCHAR(10)) + '.' AS VARCHAR(900)) AS sortpath
    FROM EmpsCTE AS M
      INNER JOIN dbo.Employees AS S
        ON S.mgrid = M.empid
        AND (M.lvl < @maxlevels OR @maxlevels IS NULL)
  )
  SELECT empid, mgrid, empname, salary, lvl, sortpath
  FROM EmpsCTE;
GO

-- test
SELECT empid, REPLICATE(' | ', lvl) + empname AS emp,
  mgrid, salary, lvl, sortpath
FROM dbo.GetSubtree(3, NULL) AS T
ORDER BY sortpath;
GO

---------------------------------------------------------------------
-- Multistatement table-valued user-defined functions
---------------------------------------------------------------------

-- definition of GetSubtree function
DROP FUNCTION IF EXISTS dbo.GetSubtree;
-- cannot use CREATE OR ALTER to change the function type
GO
CREATE FUNCTION dbo.GetSubtree (@mgrid AS INT, @maxlevels AS INT = NULL)
RETURNS @Tree TABLE
(
  empid    INT          NOT NULL PRIMARY KEY,
  mgrid    INT          NULL,
  empname  VARCHAR(25)  NOT NULL,
  salary   MONEY        NOT NULL,
  lvl      INT          NOT NULL,
  sortpath VARCHAR(892) NOT NULL,
  INDEX idx_lvl_empid_sortpath NONCLUSTERED(lvl, empid, sortpath)
)
WITH SCHEMABINDING
AS
BEGIN
  DECLARE @lvl AS INT = 0;

  -- insert subtree root node into @Tree
  INSERT INTO @Tree(empid, mgrid, empname, salary, lvl, sortpath)
    SELECT empid, NULL AS mgrid, empname, salary, @lvl AS lvl, '.' AS sortpath
    FROM dbo.Employees
    WHERE empid = @mgrid;

  WHILE @@ROWCOUNT > 0 AND (@lvl < @maxlevels OR @maxlevels IS NULL)
  BEGIN
    SET @lvl += 1;

    -- insert children of nodes from prev level into @Tree
    INSERT INTO @Tree(empid, mgrid, empname, salary, lvl, sortpath)
      SELECT S.empid, S.mgrid, S.empname, S.salary, @lvl AS lvl,
        M.sortpath + CAST(S.empid AS VARCHAR(10)) + '.' AS sortpath
      FROM dbo.Employees AS S
        INNER JOIN @Tree AS M
          ON S.mgrid = M.empid AND M.lvl = @lvl - 1;
  END;
  
  RETURN;
END;
GO

-- test
SELECT empid, REPLICATE(' | ', lvl) + empname AS emp,
  mgrid, salary, lvl, sortpath
FROM dbo.GetSubtree(3, NULL) AS T
ORDER BY sortpath;
GO

-- cleanup
DROP TABLE IF EXISTS dbo.T1;

DROP VIEW IF EXISTS dbo.VRAND;

DROP FUNCTION IF EXISTS dbo.MySYSDATETIME, dbo.MyRAND, dbo.ENDOFYEAR,
  dbo.SubtreeTotalSalaries, dbo.GetPage, dbo.GetSubtree;

DROP TABLE IF EXISTS dbo.Employees;

---------------------------------------------------------------------
-- Stored procedures
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Working with stored procedures
---------------------------------------------------------------------

-- simple procedure that handles dynamic search conditions
CREATE OR ALTER PROC dbo.GetOrders
  @orderid   AS INT  = NULL,
  @orderdate AS DATE = NULL,
  @custid    AS INT  = NULL,
  @empid     AS INT  = NULL
AS

SET XACT_ABORT, NOCOUNT ON;

SELECT orderid, orderdate, shippeddate, custid, empid, shipperid
FROM Sales.Orders
WHERE (orderid   = @orderid   OR @orderid   IS NULL)
  AND (orderdate = @orderdate OR @orderdate IS NULL)
  AND (custid    = @custid    OR @custid    IS NULL)
  AND (empid     = @empid     OR @empid     IS NULL);
GO

-- test procedure
EXEC dbo.GetOrders @orderdate = '20151111', @custid = 85;
GO
EXEC dbo.GetOrders DEFAULT, '20151111', 85, DEFAULT;
GO
EXEC dbo.GetOrders @orderid = 42;
GO

---------------------------------------------------------------------
-- Stored procedures and dynamic SQL
---------------------------------------------------------------------

-- create prcoedure with dynamic SQL
CREATE OR ALTER PROC dbo.GetOrders
  @orderid   AS INT  = NULL,
  @orderdate AS DATE = NULL,
  @custid    AS INT  = NULL,
  @empid     AS INT  = NULL
AS

SET XACT_ABORT, NOCOUNT ON;

DECLARE @sql AS NVARCHAR(MAX) = N'SELECT orderid, orderdate, shippeddate, custid, empid, shipperid
FROM Sales.Orders
WHERE 1 = 1'
  + CASE WHEN @orderid   IS NOT NULL THEN N' AND orderid   = @orderid  ' ELSE N'' END
  + CASE WHEN @orderdate IS NOT NULL THEN N' AND orderdate = @orderdate' ELSE N'' END
  + CASE WHEN @custid    IS NOT NULL THEN N' AND custid    = @custid   ' ELSE N'' END
  + CASE WHEN @empid     IS NOT NULL THEN N' AND empid     = @empid    ' ELSE N'' END
  + N';'

EXEC sys.sp_executesql
  @stmt = @sql,
  @params = N'@orderid AS INT, @orderdate AS DATE, @custid AS INT, @empid AS INT',
  @orderid   = @orderid,
  @orderdate = @orderdate,
  @custid    = @custid,
  @empid     = @empid;
GO

-- execute procedure
EXEC dbo.GetOrders @orderdate = '20151111', @custid = 85;

-- create temporary principal
CREATE LOGIN login1 WITH PASSWORD = 'J345#$)thb';  
GO  
CREATE USER user1 FOR LOGIN login1;  
GO  

-- grant permission to user1 to execute procedure
GRANT EXEC ON dbo.GetOrders TO user1;
GO

-- display current execution context
SELECT SUSER_NAME() AS [login], USER_NAME() AS [user];  

-- set the execution context to login1
EXECUTE AS LOGIN = 'login1';  

-- display current execution context again
SELECT SUSER_NAME() AS [login], USER_NAME() AS [user];  

-- try to execute procedure
EXEC dbo.GetOrders @orderdate = '20151111', @custid = 85;

-- revert back to original execution context
REVERT;
GO

-- alter prcoedure to execute as owner
CREATE OR ALTER PROC dbo.GetOrders
  @orderid   AS INT  = NULL,
  @orderdate AS DATE = NULL,
  @custid    AS INT  = NULL,
  @empid     AS INT  = NULL
WITH EXECUTE AS OWNER
AS

SET XACT_ABORT, NOCOUNT ON;

DECLARE @sql AS NVARCHAR(MAX) = N'SELECT orderid, orderdate, shippeddate, custid, empid, shipperid
FROM Sales.Orders
WHERE 1 = 1'
  + CASE WHEN @orderid   IS NOT NULL THEN N' AND orderid   = @orderid  ' ELSE N'' END
  + CASE WHEN @orderdate IS NOT NULL THEN N' AND orderdate = @orderdate' ELSE N'' END
  + CASE WHEN @custid    IS NOT NULL THEN N' AND custid    = @custid   ' ELSE N'' END
  + CASE WHEN @empid     IS NOT NULL THEN N' AND empid     = @empid    ' ELSE N'' END
  + N';'

EXEC sys.sp_executesql
  @stmt = @sql,
  @params = N'@orderid AS INT, @orderdate AS DATE, @custid AS INT, @empid AS INT',
  @orderid   = @orderid,
  @orderdate = @orderdate,
  @custid    = @custid,
  @empid     = @empid;
GO

-- set the execution context to login1
EXECUTE AS LOGIN = 'login1';  

-- try to execute procedure
EXEC dbo.GetOrders @orderdate = '20151111', @custid = 85;

-- revert back to original execution context
REVERT;

---------------------------------------------------------------------
-- Using output parameters and modifying data
---------------------------------------------------------------------

-- create table dbo.MySequences
DROP TABLE IF EXISTS dbo.MySequences;
GO
CREATE TABLE dbo.MySequences
(
  seqname VARCHAR(128) NOT NULL
    CONSTRAINT PK_MySequences PRIMARY KEY,
  val INT NOT NULL
    CONSTRAINT DFT_MySequences_val DEFAULT(0)
);
GO

-- create sequence for invoices
INSERT INTO dbo.MySequences(seqname, val) VALUES('SEQINVOICES', 0);
GO

-- create proc that returns a new sequence value for input sequence
CREATE OR ALTER PROC dbo.GetSequenceValue
  @seqname AS VARCHAR(128),
  @val     AS INT OUTPUT
AS

SET XACT_ABORT, NOCOUNT ON;

UPDATE dbo.MySequences
  SET @val = val += 1
WHERE seqname = @seqname;

IF @@ROWCOUNT = 0
  THROW 51001, 'Specified sequence was not found.', 1;
GO

-- request a new value
DECLARE @newinvoicenumber AS INT;
EXEC dbo.GetSequenceValue @seqname = 'SEQINVOICES', @val = @newinvoicenumber OUTPUT;
SELECT @newinvoicenumber AS newinvoicenumber;
GO

-- try with a sequence that doesn't exist
DECLARE @newinvoicenumber AS INT;
EXEC dbo.GetSequenceValue @seqname = 'NOSUCHSEQUENCE', @val = @newinvoicenumber OUTPUT;
SELECT @newinvoicenumber AS newinvoicenumber;
GO

---------------------------------------------------------------------
-- Using cursors
---------------------------------------------------------------------

-- create and populate table Transactions
DROP TABLE IF EXISTS dbo.Transactions;
GO
CREATE TABLE dbo.Transactions
(
  txid INT NOT NULL CONSTRAINT PK_Transactions PRIMARY KEY,
  qty  INT NOT NULL,
  depletionqty INT NULL
);
GO

TRUNCATE TABLE dbo.Transactions;
INSERT INTO dbo.Transactions(txid, qty)
  VALUES(1,2),(2,5),(3,4),(4,1),(5,10),(6,3),(7,1),(8,2),(9,1),(10,2),(11,1),(12,9);
GO

-- procedure that handles task that computes cumulative quantities in a container,
-- with the container depleted as soon as it exceeds a certain input quantity
-- the goal is to write the depletion quantity into the column depletionqty
-- see challenge at http://sqlmag.com/t-sql/t-sql-challenges-replenishing-and-depleting-quantities
CREATE OR ALTER PROC dbo.ComputeDepletionQuantities
  @maxallowedqty AS INT
AS

SET XACT_ABORT, NOCOUNT ON;

UPDATE dbo.Transactions
  SET depletionqty = NULL
WHERE depletionqty IS NOT NULL;

DECLARE @qty AS INT, @sumqty AS INT = 0;

DECLARE C CURSOR FOR
  SELECT qty
  FROM dbo.Transactions
  ORDER BY txid;

OPEN C;

FETCH NEXT FROM C INTO @qty;

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sumqty += @qty;

  IF @sumqty > @maxallowedqty
  BEGIN
    UPDATE dbo.Transactions
      SET depletionqty = @sumqty
    WHERE CURRENT OF C;

    SET @sumqty = 0;
  END;

  FETCH NEXT FROM C INTO @qty;
END;

CLOSE C;

DEALLOCATE C;

SELECT txid, qty, depletionqty,
  SUM(qty - ISNULL(depletionqty, 0))
    OVER(ORDER BY txid ROWS UNBOUNDED PRECEDING) AS totalqty
FROM dbo.Transactions
ORDER BY txid;
GO

-- test proc with @maxallowedqty = 5
EXEC dbo.ComputeDepletionQuantities @maxallowedqty = 5;

-- cleanup
DROP USER IF EXISTS user1;
GO
DROP LOGIN login1;
GO
DROP PROC IF EXISTS dbo.GetOrders, dbo.GetSequenceValue, dbo.ComputeDepletionQuantities;
DROP TABLE IF EXISTS dbo.MySequences, dbo.Transactions;
GO
