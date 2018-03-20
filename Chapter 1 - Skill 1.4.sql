---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 1 - Manage Data with Transact-SQL
-- Skill 1.4: Modify data
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Inserting data
---------------------------------------------------------------------

-- create table Sales.MyOrders
USE TSQLV4;
DROP TABLE IF EXISTS Sales.MyOrders;
GO

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL IDENTITY(1, 1)
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
  custid  INT NOT NULL,
  empid   INT NOT NULL,
  orderdate DATE NOT NULL
    CONSTRAINT DFT_MyOrders_orderdate DEFAULT (CAST(SYSDATETIME() AS DATE)),
  shipcountry NVARCHAR(15) NOT NULL,
  freight MONEY NOT NULL
);

---------------------------------------------------------------------
-- INSERT VALUES
---------------------------------------------------------------------

-- single row
INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight)
  VALUES(2, 19, '20170620', N'USA', 30.00);

-- relying on defaults
INSERT INTO Sales.MyOrders(custid, empid, shipcountry, freight)
  VALUES(3, 11, N'USA', 10.00);

INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight)
  VALUES(3, 17, DEFAULT, N'USA', 30.00);

-- multiple rows
INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight) VALUES
  (2, 11, '20170620', N'USA', 50.00),
  (5, 13, '20170620', N'USA', 40.00),
  (7, 17, '20170620', N'USA', 45.00);

-- query the table
SELECT * FROM Sales.MyOrders;

---------------------------------------------------------------------
-- INSERT SELECT
---------------------------------------------------------------------

SET IDENTITY_INSERT Sales.MyOrders ON;

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
  SELECT orderid, custid, empid, orderdate, shipcountry, freight
  FROM Sales.Orders
  WHERE shipcountry = N'Norway';

SET IDENTITY_INSERT Sales.MyOrders OFF;

-- query the table
SELECT * FROM Sales.MyOrders;

---------------------------------------------------------------------
-- INSERT EXEC
---------------------------------------------------------------------

-- create procedure
DROP PROC IF EXISTS Sales.OrdersForCountry;
GO

CREATE PROC Sales.OrdersForCountry
  @country AS NVARCHAR(15)
AS

SELECT orderid, custid, empid, orderdate, shipcountry, freight
FROM Sales.Orders
WHERE shipcountry = @country;
GO

-- insert the result of the procedure
SET IDENTITY_INSERT Sales.MyOrders ON;

INSERT INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
  EXEC Sales.OrdersForCountry
    @country = N'Portugal';

SET IDENTITY_INSERT Sales.MyOrders OFF;

-- query the table
SELECT * FROM Sales.MyOrders;

---------------------------------------------------------------------
-- SELECT INTO
---------------------------------------------------------------------

-- simple SELECT INTO
DROP TABLE IF EXISTS Sales.MyOrders;

SELECT orderid, custid, orderdate, shipcountry, freight
INTO Sales.MyOrders
FROM Sales.Orders
WHERE shipcountry = N'Norway';

-- remove identity property, make column NULLable, change column's type
DROP TABLE IF EXISTS Sales.MyOrders;

SELECT 
  ISNULL(orderid + 0, -1) AS orderid, -- get rid of identity property
                                      -- make column NOT NULL
  ISNULL(custid, -1) AS custid, -- make column NOT NULL
  empid, 
  ISNULL(CAST(orderdate AS DATE), '19000101') AS orderdate,
  shipcountry, freight
INTO Sales.MyOrders
FROM Sales.Orders
WHERE shipcountry = N'Norway';

-- create constraints
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

-- query the table
SELECT * FROM Sales.MyOrders;

-- cleanup
DROP TABLE IF EXISTS Sales.MyOrders;

---------------------------------------------------------------------
-- Updating data
---------------------------------------------------------------------

-- sample data for UPDATE and DELETE sections
DROP TABLE IF EXISTS Sales.MyOrderDetails, Sales.MyOrders, Sales.MyCustomers;

SELECT * INTO Sales.MyCustomers FROM Sales.Customers;
ALTER TABLE Sales.MyCustomers
  ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT * INTO Sales.MyOrders FROM Sales.Orders;
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

SELECT * INTO Sales.MyOrderDetails FROM Sales.OrderDetails;
ALTER TABLE Sales.MyOrderDetails
  ADD CONSTRAINT PK_MyOrderDetails PRIMARY KEY(orderid, productid);

---------------------------------------------------------------------
-- UPDATE statement
---------------------------------------------------------------------

-- add 5 percent discount to order lines of order 10251

-- first show current state
SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10251;

-- update
UPDATE Sales.MyOrderDetails
  SET discount += 0.05
WHERE orderid = 10251;

-- show state after update
SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10251;

-- cleanup
UPDATE Sales.MyOrderDetails
  SET discount -= 0.05
WHERE orderid = 10251;

/*
UPDATE dbo.MyTable SET discount += 0.05 WHERE CURRENT OF MyCursor;
*/

---------------------------------------------------------------------
-- UPDATE based on join
---------------------------------------------------------------------

-- show state before update
SELECT OD.*
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- update
UPDATE OD
  SET OD.discount += 0.05
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- state after update
SELECT OD.*
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- cleanup
UPDATE OD
  SET OD.discount -= 0.05
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
  INNER JOIN Sales.MyOrderDetails AS OD
    ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

---------------------------------------------------------------------
-- Nondeterministic UPDATE
---------------------------------------------------------------------

-- show current state
SELECT C.custid, C.postalcode, O.shippostalcode
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid
ORDER BY C.custid;

-- update
UPDATE C
  SET C.postalcode = O.shippostalcode
FROM Sales.MyCustomers AS C
  INNER JOIN Sales.MyOrders AS O
    ON C.custid = O.custid;

-- show state after update
SELECT custid, postalcode
FROM Sales.MyCustomers
ORDER BY custid;

-- update to the postal code associated with the first order
UPDATE C
  SET C.postalcode = A.shippostalcode
FROM Sales.MyCustomers AS C
  CROSS APPLY (SELECT TOP (1) O.shippostalcode
               FROM Sales.MyOrders AS O
               WHERE O.custid = C.custid
               ORDER BY orderdate, orderid) AS A;

-- show state after update
SELECT custid, postalcode
FROM Sales.MyCustomers
ORDER BY custid;

---------------------------------------------------------------------
-- UPDATE based on a variable
---------------------------------------------------------------------

-- current state of the data
SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10250
  AND productid = 51;
GO

DECLARE @newdiscount AS NUMERIC(4, 3) = NULL;

UPDATE Sales.MyOrderDetails
  SET @newdiscount = discount += 0.05
WHERE orderid = 10250
  AND productid = 51;

SELECT @newdiscount;
GO

-- cleanup
UPDATE Sales.MyOrderDetails
  SET discount -= 0.05
WHERE orderid = 10250
  AND productid = 51;

---------------------------------------------------------------------
-- UPDATE all-at-once
---------------------------------------------------------------------

-- create table T1
DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1
(
  keycol INT NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY,
  col1 INT NOT NULL, 
  col2 INT NOT NULL
);

INSERT INTO dbo.T1(keycol, col1, col2) VALUES(1, 100, 0);
GO

-- what's the value of col2 after the following UPDATE
DECLARE @add AS INT = 10;

UPDATE dbo.T1
  SET col1 += @add, col2 = col1
WHERE keycol = 1;

SELECT * FROM dbo.T1;

-- cleanup
DROP TABLE IF EXISTS dbo.T1;

---------------------------------------------------------------------
-- Deleting data
---------------------------------------------------------------------

-- sample data
DROP TABLE IF EXISTS Sales.MyOrderDetails, Sales.MyOrders, Sales.MyCustomers;

SELECT * INTO Sales.MyCustomers FROM Sales.Customers;
ALTER TABLE Sales.MyCustomers
  ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT * INTO Sales.MyOrders FROM Sales.Orders;
ALTER TABLE Sales.MyOrders
  ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

SELECT * INTO Sales.MyOrderDetails FROM Sales.OrderDetails;
ALTER TABLE Sales.MyOrderDetails
  ADD CONSTRAINT PK_MyOrderDetails PRIMARY KEY(orderid, productid);

-- DELETE statement
DELETE FROM Sales.MyOrderDetails
WHERE productid = 11;

/*
DELETE FROM dbo.MyTable WHERE CURRENT OF MyCursor;
*/

-- delete in chuncks
WHILE 1 = 1
BEGIN
  DELETE TOP (1000) FROM Sales.MyOrderDetails
  WHERE productid = 12;

  IF @@rowcount < 1000 BREAK;
END

-- TRUNCATE statement
TRUNCATE TABLE Sales.MyOrderDetails;

-- With partitions
TRUNCATE TABLE MyTable WITH ( PARTITIONS(1, 2, 11 TO 20) );

-- DELETE based on a join
DELETE FROM O
FROM Sales.MyOrders AS O
  INNER JOIN Sales.MyCustomers AS C
    ON O.custid = C.custid
WHERE C.country = N'USA';

-- cleanup
DROP TABLE IF EXISTS Sales.MyOrderDetails, Sales.MyOrders, Sales.MyCustomers;

---------------------------------------------------------------------
-- Merging data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Using the MERGE statement
---------------------------------------------------------------------

-- create table and sequence if they don't already exist
DROP TABLE IF EXISTS Sales.MyOrders;
DROP SEQUENCE IF EXISTS Sales.SeqOrderIDs;

CREATE SEQUENCE Sales.SeqOrderIDs AS INT
  MINVALUE 1
  CACHE 10000;

CREATE TABLE Sales.MyOrders
(
  orderid INT NOT NULL
    CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
    CONSTRAINT DFT_MyOrders_orderid
      DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
  custid  INT NOT NULL
    CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
  empid   INT NOT NULL
    CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
  orderdate DATE NOT NULL
);
GO

-- update where exists, insert where not exists
DECLARE
  @orderid   AS INT  = 1, @custid    AS INT  = 1,
  @empid     AS INT  = 2, @orderdate AS DATE = '20170212';

MERGE INTO Sales.MyOrders WITH (SERIALIZABLE) AS TGT
USING (VALUES(@orderid, @custid, @empid, @orderdate))
       AS SRC( orderid,  custid,  empid,  orderdate)
  ON SRC.orderid = TGT.orderid
WHEN MATCHED THEN
  UPDATE
    SET TGT.custid    = SRC.custid,
        TGT.empid     = SRC.empid,
        TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN
  INSERT VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);
GO

-- update where exists (only if different), insert where not exists
DECLARE
  @orderid   AS INT  = 1, @custid    AS INT  = 1,
  @empid     AS INT  = 2, @orderdate AS DATE = '20170212';

MERGE INTO Sales.MyOrders WITH (SERIALIZABLE) AS TGT
USING (VALUES(@orderid, @custid, @empid, @orderdate))
       AS SRC( orderid,  custid,  empid,  orderdate)
  ON SRC.orderid = TGT.orderid
WHEN MATCHED AND (   TGT.custid    <> SRC.custid
                  OR TGT.empid     <> SRC.empid
                  OR TGT.orderdate <> SRC.orderdate) THEN
  UPDATE
    SET TGT.custid    = SRC.custid,
        TGT.empid     = SRC.empid,
        TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN
  INSERT VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);
GO

-- Alternative: WHEN MATCHED AND EXISTS( SELECT SRC.* EXCEPT SELECT TGT.* ) THEN UPDATE

-- table as source
DECLARE @Orders AS TABLE
(
  orderid   INT  NOT NULL PRIMARY KEY,
  custid    INT  NOT NULL,
  empid     INT  NOT NULL,
  orderdate DATE NOT NULL
);

INSERT INTO @Orders(orderid, custid, empid, orderdate)
  VALUES (2, 1, 3, '20170212'),
         (3, 2, 2, '20170212'),
         (4, 3, 5, '20170212');

-- update where exists (only if different), insert where not exists,
-- delete when exists in target but not in source
MERGE INTO Sales.MyOrders AS TGT
USING @Orders AS SRC
  ON SRC.orderid = TGT.orderid
WHEN MATCHED AND EXISTS( SELECT SRC.* EXCEPT SELECT TGT.* ) THEN
  UPDATE
    SET TGT.custid    = SRC.custid,
        TGT.empid     = SRC.empid,
        TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN
  INSERT VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;

-- query table
SELECT * FROM Sales.MyOrders;

---------------------------------------------------------------------
-- Using the OUTPUT Option 
---------------------------------------------------------------------

-- clear table and reset sequence if the already exist
TRUNCATE TABLE Sales.MyOrders;
ALTER SEQUENCE Sales.SeqOrderIDs RESTART WITH 1;

---------------------------------------------------------------------
-- INSERT with OUTPUT
---------------------------------------------------------------------

INSERT INTO Sales.MyOrders(custid, empid, orderdate)
  OUTPUT
    inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
  SELECT custid, empid, orderdate
  FROM Sales.Orders
  WHERE shipcountry = N'Norway';

-- could use INTO
/*
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
  OUTPUT
    inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
    INTO SomeTable(orderid, custid, empid, orderdate)
  SELECT custid, empid, orderdate
  FROM Sales.Orders
  WHERE shipcountry = N'Norway';
*/

---------------------------------------------------------------------
-- DELETE with OUTPUT
---------------------------------------------------------------------

DELETE FROM Sales.MyOrders
  OUTPUT deleted.orderid
WHERE empid = 1;

---------------------------------------------------------------------
-- UPDATE with OUTPUT
---------------------------------------------------------------------

UPDATE Sales.MyOrders
  SET orderdate = DATEADD(day, 1, orderdate)
  OUTPUT
    inserted.orderid,
    deleted.orderdate AS old_orderdate,
    inserted.orderdate AS neworderdate
WHERE empid = 7;

---------------------------------------------------------------------
-- MERGE with OUTPUT
---------------------------------------------------------------------

MERGE INTO Sales.MyOrders AS TGT
USING (VALUES(1, 70, 1, '20151218'), (2, 70, 7, '20160429'), (3, 70, 7, '20160820'),
             (4, 70, 3, '20170114'), (5, 70, 1, '20170226'), (6, 70, 2, '20170410'))
       AS SRC(orderid, custid, empid, orderdate)
  ON SRC.orderid = TGT.orderid
WHEN MATCHED AND EXISTS( SELECT SRC.* EXCEPT SELECT TGT.* ) THEN
  UPDATE SET TGT.custid    = SRC.custid,
             TGT.empid     = SRC.empid,
             TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN
  INSERT VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE
OUTPUT
  $action AS the_action,
  COALESCE(inserted.orderid, deleted.orderid) AS orderid;

MERGE INTO Sales.MyOrders AS TGT
USING ( SELECT orderid, custid, empid, orderdate
        FROM Sales.Orders
        WHERE shipcountry = N'Norway' ) AS SRC
  ON 1 = 2
WHEN NOT MATCHED THEN
  INSERT(custid, empid, orderdate) VALUES(custid, empid, orderdate)
OUTPUT
  SRC.orderid AS srcorderid, inserted.orderid AS tgtorderid,
  inserted.custid, inserted.empid, inserted.orderdate;

-- clear table
TRUNCATE TABLE Sales.MyOrders;
ALTER SEQUENCE Sales.SeqOrderIDs RESTART WITH 1; 

---------------------------------------------------------------------
-- Nested DML
---------------------------------------------------------------------

DECLARE @InsertedOrders AS TABLE
(
  orderid   INT  NOT NULL PRIMARY KEY,
  custid    INT  NOT NULL,
  empid     INT  NOT NULL,
  orderdate DATE NOT NULL
);

INSERT INTO @InsertedOrders(orderid, custid, empid, orderdate)
  SELECT orderid, custid, empid, orderdate
  FROM (MERGE INTO Sales.MyOrders AS TGT
    USING (VALUES(1, 70, 1, '20151218'), (2, 70, 7, '20160429'), (3, 70, 7, '20160820'),
                 (4, 70, 3, '20170114'), (5, 70, 1, '20170226'), (6, 70, 2, '20170410'))
               AS SRC(orderid, custid, empid, orderdate)
          ON SRC.orderid = TGT.orderid
        WHEN MATCHED AND EXISTS( SELECT SRC.* EXCEPT SELECT TGT.* ) THEN
          UPDATE SET TGT.custid    = SRC.custid,
                     TGT.empid     = SRC.empid,
                     TGT.orderdate = SRC.orderdate
        WHEN NOT MATCHED THEN
          INSERT VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
        WHEN NOT MATCHED BY SOURCE THEN
          DELETE
        OUTPUT
          $action AS the_action, inserted.*) AS D
  WHERE the_action = 'INSERT';

SELECT * FROM @InsertedOrders;

---------------------------------------------------------------------
-- Impact of structural changes on data
---------------------------------------------------------------------

-- Sample data
TRUNCATE TABLE Sales.MyOrders;
ALTER SEQUENCE Sales.SeqOrderIDs RESTART WITH 1;
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
  VALUES(70, 1, '20151218'), (70, 7, '20160429'), (70, 7, '20160820'),
        (70, 3, '20170114'), (70, 1, '20170226'), (70, 2, '20170410');

---------------------------------------------------------------------
-- Adding a column
---------------------------------------------------------------------

-- Following fails
ALTER TABLE Sales.MyOrders ADD requireddate DATE NOT NULL;

-- Following succeeds
ALTER TABLE Sales.MyOrders
  ADD requireddate DATE NOT NULL
  CONSTRAINT DFT_MyOrders_requireddate DEFAULT ('19000101') WITH VALUES;

-- All rows have January 1st, 1900 in the requireddate column
SELECT * FROM Sales.MyOrders;

---------------------------------------------------------------------
-- Droping a column
---------------------------------------------------------------------

-- Following fails
ALTER TABLE Sales.MyOrders DROP COLUMN requireddate;

---------------------------------------------------------------------
-- Altering a column
---------------------------------------------------------------------

-- Following fails
ALTER TABLE Sales.MyOrders ALTER COLUMN requireddate DATETIME NOT NULL;

-- Following succeeds
ALTER TABLE Sales.MyOrders ALTER COLUMN requireddate DATE NULL;

-- Following succeeds as long as there are no NULLs in the column
ALTER TABLE Sales.MyOrders ALTER COLUMN requireddate DATE NOT NULL;

-- Drop default
ALTER TABLE Sales.MyOrders DROP CONSTRAINT DFT_MyOrders_orderid;

-- Add default
ALTER TABLE Sales.MyOrders ADD CONSTRAINT DFT_MyOrders_orderid
  DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs) FOR orderid;

-- cleanup
DROP TABLE IF EXISTS Sales.MyOrders;
DROP SEQUENCE IF EXISTS Sales.SeqOrderIDs;
