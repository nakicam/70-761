---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 3 - Program databases by using Transact-SQL
-- Skill 3.2: Implement error handling and transactions
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Understanding transactions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Defining transactions
---------------------------------------------------------------------

-- transaction example
USE TSQLV4;
SET XACT_ABORT, NOCOUNT ON;

-- start a new transaction
BEGIN TRAN;

-- declare a variable
DECLARE @neworderid AS INT;

-- insert a new order into the Sales.Orders table
INSERT INTO Sales.Orders
    (custid, empid, orderdate, requireddate, shippeddate, 
     shipperid, freight, shipname, shipaddress, shipcity,
     shippostalcode, shipcountry)
  VALUES
    (1, 1, '20170212', '20170301', '20170216',
     1, 10.00, N'Shipper 1', N'Address AAA', N'City AAA',
     N'11111', N'Country AAA');

-- save the new order id in the variable @neworderid
SET @neworderid = SCOPE_IDENTITY();

PRINT 'Added new order header with order ID ' + CAST(@neworderid AS VARCHAR(10))
  + '. @@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

-- insert order lines for new order into Sales.OrderDetails
INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
  VALUES(@neworderid, 1, 10.00, 1, 0.000),
        (@neworderid, 2, 10.00, 1, 0.000),
        (@neworderid, 3, 10.00, 1, 0.000);

PRINT 'Added order lines to new order. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

-- commit the transaction
COMMIT TRAN;
GO

-- query the data for the new order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderid = 11078;

SELECT orderid, productid, qty
FROM Sales.OrderDetails
WHERE orderid = 11078;
GO

-- try adding an order with an invalid order line
SET XACT_ABORT, NOCOUNT ON;

BEGIN TRAN;

DECLARE @neworderid AS INT;

INSERT INTO Sales.Orders
    (custid, empid, orderdate, requireddate, shippeddate, 
     shipperid, freight, shipname, shipaddress, shipcity,
     shippostalcode, shipcountry)
  VALUES
    (2, 2, '20170212', '20170301', '20170216',
     2, 20.00, N'Shipper 2', N'Address BBB', N'City BBB',
     N'22222', N'Country BBB');

SET @neworderid = SCOPE_IDENTITY();

PRINT 'Added new order header with order ID ' + CAST(@neworderid AS VARCHAR(10))
  + '. @@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
  VALUES(@neworderid, 1, 20.00, 2, 2.000), -- CHECK violation since discount > 1
        (@neworderid, 2, 20.00, 2, 0.000),
        (@neworderid, 3, 20.00, 2, 0.000);

PRINT 'Added order lines to new order. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

COMMIT TRAN;
GO

-- examine constraints on Sales.OrderDetails
EXEC sys.sp_helpconstraint 'Sales.OrderDetails';

-- query the data for the new order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderid = 11079;

SELECT orderid, productid, qty
FROM Sales.OrderDetails
WHERE orderid = 11079;
GO

-- autocommit example
SET XACT_ABORT, NOCOUNT ON;

DECLARE @neworderid AS INT;

INSERT INTO Sales.Orders
    (custid, empid, orderdate, requireddate, shippeddate, 
     shipperid, freight, shipname, shipaddress, shipcity,
     shippostalcode, shipcountry)
  VALUES
    (3, 3, '20170212', '20170301', '20170216',
     3, 30.00, N'Shipper 3', N'Address CCC', N'City CCC',
     N'33333', N'Country CCC');

SET @neworderid = SCOPE_IDENTITY();

PRINT 'Added new order header with order ID ' + CAST(@neworderid AS VARCHAR(10))
  + '. @@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
  VALUES(@neworderid, 1, 30.00, 3, 2.000), -- CHECK violation since discount > 1
        (@neworderid, 2, 30.00, 3, 0.000),
        (@neworderid, 3, 30.00, 3, 0.000);

PRINT 'Added order lines to new order. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
GO

-- query the data for the new order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderid = 11080;

SELECT orderid, productid, qty
FROM Sales.OrderDetails
WHERE orderid = 11080;
GO

-- IMPLICIT TRANSACTIONS
SET IMPLICIT_TRANSACTIONS ON;

-- test code under implicit transactions mode
SET XACT_ABORT, NOCOUNT ON;

DECLARE @neworderid AS INT;

-- following statement triggers the opening of a transaction but doesn't close it
INSERT INTO Sales.Orders
    (custid, empid, orderdate, requireddate, shippeddate, 
     shipperid, freight, shipname, shipaddress, shipcity,
     shippostalcode, shipcountry)
  VALUES
    (4, 4, '20170212', '20170301', '20170216',
     1, 40.00, N'Shipper 1', N'Address AAA', N'City AAA',
     N'11111', N'Country AAA');

SET @neworderid = SCOPE_IDENTITY();

PRINT 'Added new order header with order ID ' + CAST(@neworderid AS VARCHAR(10))
  + '. @@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
  VALUES(@neworderid, 1, 40.00, 4, 0.000),
        (@neworderid, 2, 40.00, 4, 0.000),
        (@neworderid, 3, 40.00, 4, 0.000);

PRINT 'Added order lines to new order. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

-- must explicitly commit the transaction
COMMIT TRAN;
GO

-- query the data for the new order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderid = 11081;

SELECT orderid, productid, qty
FROM Sales.OrderDetails
WHERE orderid = 11081;
GO

-- turn implicit transactions to off
SET IMPLICIT_TRANSACTIONS OFF;

-- example with DDL
DROP TABLE IF EXISTS dbo.T1;

BEGIN TRAN;

CREATE TABLE dbo.T1(col1 INT);
INSERT INTO dbo.T1(col1) VALUES(1),(2),(3);
PRINT 'In transaction';
SELECT col1 FROM dbo.T1;

ROLLBACK TRAN;

PRINT 'After transaction';
SELECT col1 FROM dbo.T1;

-- rollback doesn't effect variables including table variables
BEGIN TRAN;

DECLARE @T1 AS TABLE(col1 INT);
INSERT INTO @T1(col1) VALUES(1),(2),(3);
PRINT 'In transaction';
SELECT col1 FROM @T1;

ROLLBACK TRAN;

PRINT 'After transaction';
SELECT col1 FROM @T1;
GO

---------------------------------------------------------------------
-- Nesting of transactions
---------------------------------------------------------------------

-- example for nesting BEGIN TRAN statements
SET NOCOUNT ON;
DROP TABLE IF EXISTS dbo.T1;
GO
CREATE TABLE dbo.T1(col1 INT);

PRINT '@@TRANCOUNT before first BEGIN TRAN is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

BEGIN TRAN;

PRINT '@@TRANCOUNT after first BEGIN TRAN is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

BEGIN TRAN;

PRINT '@@TRANCOUNT after second BEGIN TRAN is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

BEGIN TRAN;

PRINT '@@TRANCOUNT after third BEGIN TRAN is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

INSERT INTO dbo.T1 VALUES(1),(2),(3);

COMMIT TRAN; -- this doesn't really commit

PRINT '@@TRANCOUNT after first COMMIT TRAN is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

ROLLBACK TRAN; -- this does roll the transaction back

PRINT '@@TRANCOUNT after ROLLBACK TRAN is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

SELECT col1 FROM dbo.T1;
GO

-- create table type OrderLines
DROP TYPE IF EXISTS dbo.OrderLines;
GO
CREATE TYPE dbo.OrderLines AS TABLE
(
  productid INT           NOT NULL PRIMARY KEY,
  unitprice MONEY         NOT NULL CHECK (unitprice >= 0),
  qty       SMALLINT      NOT NULL CHECK (qty > 0),
  discount  NUMERIC(4, 3) NOT NULL CHECK (discount BETWEEN 0 AND 1)
);
GO

-- create AddOrder stored procedure
CREATE OR ALTER PROC dbo.AddOrder
  @custid         AS INT,
  @empid          AS INT,
  @orderdate      AS DATE,
  @requireddate   AS DATE,
  @shippeddate    AS DATE,
  @shipperid      AS INT,
  @freight        AS MONEY,
  @shipname       AS NVARCHAR(40),
  @shipaddress    AS NVARCHAR(60),
  @shipcity       AS NVARCHAR(15),
  @shipregion     AS NVARCHAR(15),
  @shippostalcode AS NVARCHAR(10),
  @shipcountry    AS NVARCHAR(15),
  @OrderLines     AS dbo.OrderLines READONLY,
  @neworderid     AS INT OUT
AS

SET XACT_ABORT, NOCOUNT ON;

BEGIN TRAN;

-- add order header
INSERT INTO Sales.Orders
    (custid, empid, orderdate, requireddate, shippeddate, 
     shipperid, freight, shipname, shipaddress, shipcity,
     shippostalcode, shipcountry)
  VALUES
    (@custid, @empid, @orderdate, @requireddate, @shippeddate, 
     @shipperid, @freight, @shipname, @shipaddress, @shipcity,
     @shippostalcode, @shipcountry);

SET @neworderid = SCOPE_IDENTITY();

-- add order lines
INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
  SELECT @neworderid, productid, unitprice, qty, discount
  FROM @OrderLines;

COMMIT TRAN;
GO

-- example for executing stored procedure
DECLARE @MyOrderLines AS dbo.OrderLines, @myneworderid AS INT;

INSERT INTO @MyOrderLines(productid, unitprice, qty, discount)
  VALUES(1, 50.00, 5, 0.000),
        (2, 50.00, 5, 0.000),
        (3, 50.00, 5, 0.000);

EXEC dbo.AddOrder
  @custid         = 5,
  @empid          = 5,
  @orderdate      = '20170212',
  @requireddate   = '20170301',
  @shippeddate    = '20170216',
  @shipperid      = 2,
  @freight        = 50.00,
  @shipname       = N'Shipper 2',
  @shipaddress    = N'Address BBB',
  @shipcity       = N'City BBB',
  @shipregion     = N'Region BBB',
  @shippostalcode = N'22222',
  @shipcountry    = N'Country BBB',
  @OrderLines     = @MyOrderLines,
  @neworderid     = @myneworderid OUT;

PRINT 'Added new order with order ID '
  + CAST(@myneworderid AS VARCHAR(10)) + '.';
GO

-- query the data for the new order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderid = 11082;

SELECT orderid, productid, qty
FROM Sales.OrderDetails
WHERE orderid = 11082;
GO

-- execute proce from a transaction and then roll the transaction back
BEGIN TRAN;

DECLARE @MyOrderLines AS dbo.OrderLines, @myneworderid AS INT;

INSERT INTO @MyOrderLines(productid, unitprice, qty, discount)
  VALUES(1, 60.00, 6, 0.000),
        (2, 60.00, 6, 0.000),
        (3, 60.00, 6, 0.000);

EXEC dbo.AddOrder
  @custid         = 6,
  @empid          = 6,
  @orderdate      = '20170212',
  @requireddate   = '20170301',
  @shippeddate    = '20170216',
  @shipperid      = 3,
  @freight        = 60.00,
  @shipname       = N'Shipper 3',
  @shipaddress    = N'Address CCC',
  @shipcity       = N'City CCC',
  @shipregion     = N'Region CCC',
  @shippostalcode = N'33333',
  @shipcountry    = N'Country CCC',
  @OrderLines     = @MyOrderLines,
  @neworderid     = @myneworderid OUT;

PRINT 'Added new order with order ID '
  + CAST(@myneworderid AS VARCHAR(10)) + '.';

ROLLBACK TRAN;
GO

-- query the data for the new order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderid = 11083;

SELECT orderid, productid, qty
FROM Sales.OrderDetails
WHERE orderid = 11083;
GO

-- create procedure Proc1
CREATE OR ALTER PROC dbo.Proc1
AS

SET XACT_ABORT, NOCOUNT ON;

BEGIN TRAN;

PRINT 'In transaction in proc. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

CREATE TABLE dbo.DoIExist(col1 int);

WHILE @@TRANCOUNT > 0
  COMMIT TRAN;

PRINT 'Still in proc. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
GO

-- test proc
DROP TABLE IF EXISTS dbo.DoIExist;

EXEC dbo.Proc1;

IF OBJECT_ID('dbo.DoIExist') IS NOT NULL
  PRINT 'DoIExist exists.'
ELSE
  PRINT 'DoIExist does not exist.';

PRINT 'Still in batch. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
GO

-- test proc from outer transaction
DROP TABLE IF EXISTS dbo.DoIExist;

BEGIN TRAN;

EXEC dbo.Proc1;

PRINT 'Still in batch. @@TRANCOUNT is '
  + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

IF @@TRANCOUNT > 0
  ROLLBACK TRAN;

IF OBJECT_ID('dbo.DoIExist') IS NOT NULL
  PRINT 'DoIExist exists.'
ELSE
  PRINT 'DoIExist does not exist.';

---------------------------------------------------------------------
-- Working with named transactions, savepoints and markers
---------------------------------------------------------------------

-- named transactions, example 1
SET XACT_ABORT OFF;
BEGIN TRAN OutermostTran;
BEGIN TRAN InnerTran1;
BEGIN TRAN InnerTran2;
ROLLBACK TRAN OutermostTran;
PRINT '@@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
GO

-- named transactions, example 2
SET XACT_ABORT OFF;
BEGIN TRAN OutermostTran;
BEGIN TRAN InnerTran1;
BEGIN TRAN InnerTran2;
ROLLBACK TRAN InnerTran1;
PRINT '@@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
GO
ROLLBACK TRAN;

-- savepoints
SET XACT_ABORT, NOCOUNT ON;
DROP TABLE IF EXISTS dbo.T1;
GO
CREATE TABLE dbo.T1(col1 VARCHAR(10));
GO

BEGIN TRAN;

SAVE TRAN S1;
INSERT INTO dbo.T1(col1) VALUES('S1');

SAVE TRAN S2;
INSERT INTO dbo.T1(col1) VALUES('S2');

SAVE TRAN S3;
INSERT INTO dbo.T1(col1) VALUES('S3');

ROLLBACK TRAN S3;

ROLLBACK TRAN S2;

SAVE TRAN S4;
INSERT INTO dbo.T1(col1) VALUES('S4');

COMMIT TRAN;

SELECT col1 FROM dbo.T1;
GO
DROP TABLE IF EXISTS dbo.T1;
GO

---------------------------------------------------------------------
-- Error handling with TRY-CATCH
---------------------------------------------------------------------

---------------------------------------------------------------------
-- The TRY-CATCH construct
---------------------------------------------------------------------

-- sample table
SET NOCOUNT ON;
USE TSQLV4;

DROP TABLE IF EXISTS dbo.T1;
GO
CREATE TABLE dbo.T1
(
  keycol INT NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY,
  col1 INT NOT NULL
    CONSTRAINT CHK_T1_col1_gtzero CHECK(col1 > 0),
  col2 VARCHAR(10) NOT NULL
);

-- succesfull execution of TRY block
BEGIN TRY

  INSERT INTO dbo.T1(keycol, col1, col2)
    VALUES(1, 10, 'AAA');
  INSERT INTO dbo.T1(keycol, col1, col2)
    VALUES(2, 20, 'BBB');

  PRINT 'Got to the end of the TRY block.';

END TRY
BEGIN CATCH

  PRINT 'Error occurred. Entering CATCH block. Error message: ' + ERROR_MESSAGE();

END CATCH;
GO

SELECT keycol, col1, col2
FROM dbo.T1;

-- cleanup
TRUNCATE TABLE dbo.T1;

-- Error in TRY block
BEGIN TRY

  INSERT INTO dbo.T1(keycol, col1, col2)
    VALUES(1, 10, 'AAA');
  INSERT INTO dbo.T1(keycol, col1, col2)
    VALUES(2, -20, 'BBB');

  PRINT 'Got to the end of the TRY block.';

END TRY
BEGIN CATCH

  PRINT 'Error occurred. Entering CATCH block. Error message: ' + ERROR_MESSAGE();

END CATCH;
GO

SELECT keycol, col1, col2
FROM dbo.T1;

-- cleanup
TRUNCATE TABLE dbo.T1;
GO

-- create table ErrorLog
DROP TABLE IF EXISTS dbo.ErrorLog;
GO
CREATE TABLE dbo.ErrorLog
(
  id INT NOT NULL IDENTITY
    CONSTRAINT PK_ErrorLog PRIMARY KEY,
  dt DATETIME2 NOT NULL DEFAULT(SYSDATETIME()),
  loginname NVARCHAR(128) NOT NULL DEFAULT(SUSER_SNAME()),
  errormessage NVARCHAR(4000) NOT NULL
);
GO

-- example for nested TRY-CATCH
CREATE OR ALTER PROC dbo.AddRowToT1
  @keycol INT,
  @col1   INT,
  @col2   VARCHAR(10)
AS

SET NOCOUNT ON;

BEGIN TRY

  INSERT INTO dbo.T1(keycol, col1, col2)
    VALUES(@keycol, @col1, @col2);

  PRINT 'Got to the end of the outer TRY block.';

END TRY
BEGIN CATCH

  PRINT 'Error occurred in outer TRY block. Entering outer CATCH block.';

  BEGIN TRY
  
    INSERT INTO dbo.ErrorLog(errormessage) VALUES(ERROR_MESSAGE());

    PRINT 'Got to the end of the inner TRY block.';

  END TRY
  BEGIN CATCH

    PRINT 'Error occurred in inner TRY block. Entering inner CATCH block. Error message: ' + ERROR_MESSAGE();
  
  END CATCH;

END CATCH;
GO

-- example for execution with no errors
EXEC dbo.AddRowToT1
  @keycol = 1,
  @col1 = 10,
  @col2 = 'AAA';
GO

SELECT keycol, col1, col2 FROM dbo.T1;
SELECT id, dt, loginname, errormessage FROM dbo.ErrorLog;

-- cleanup
TRUNCATE TABLE dbo.T1;
TRUNCATE TABLE dbo.ErrorLog;
GO

-- example for execution with error in outer TRY
EXEC dbo.AddRowToT1
  @keycol = 1,
  @col1 = -10,
  @col2 = 'BBB';
GO

SELECT keycol, col1, col2 FROM dbo.T1;
SELECT id, dt, loginname, errormessage FROM dbo.ErrorLog;

-- cleanup
TRUNCATE TABLE dbo.T1;
TRUNCATE TABLE dbo.ErrorLog;
GO

-- example for execution with error in inner TRY

-- in connection 1
BEGIN TRAN;

SELECT TOP (0) * FROM dbo.ErrorLog WITH (TABLOCKX);
GO

-- in connection 2
SET LOCK_TIMEOUT 0;

EXEC dbo.AddRowToT1
  @keycol = 1,
  @col1 = -10,
  @col2 = 'BBB';
GO

-- in connection 1
COMMIT TRAN;

-- in connection 2
SELECT keycol, col1, col2 FROM dbo.T1;
SELECT id, dt, loginname, errormessage FROM dbo.ErrorLog;

-- cleanup
TRUNCATE TABLE dbo.T1;
TRUNCATE TABLE dbo.ErrorLog;
SET LOCK_TIMEOUT -1;
GO

-- InnerProc
CREATE OR ALTER PROC dbo.InnerProc
AS

BEGIN TRY
  SELECT nosuchcolumn FROM dbo.NoSuchTable;
END TRY
BEGIN CATCH
  PRINT 'In CATCH block of InnerProc.';
END CATCH;
GO

-- test InnerProc
EXEC dbo.InnerProc;;

-- OuterProc
CREATE OR ALTER PROC dbo.OuterProc
AS

BEGIN TRY
  EXEC dbo.InnerProc;
END TRY
BEGIN CATCH
  PRINT 'In CATCH block of OuterProc.';
END CATCH;
GO

-- test OuterProc
EXEC dbo.OuterProc;
GO

---------------------------------------------------------------------
-- Error functions
---------------------------------------------------------------------

-- PrintErrorInfo procedure
CREATE OR ALTER PROC dbo.PrintErrorInfo
AS

PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
PRINT 'Error Message : ' + ERROR_MESSAGE();
PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
PRINT 'Error State   : ' + CAST(ERROR_STATE() AS VARCHAR(10));
PRINT 'Error Line    : ' + CAST(ERROR_LINE() AS VARCHAR(10));
PRINT 'Error Proc    : ' + COALESCE(ERROR_PROCEDURE(), 'Not within proc');
GO

-- AddRowToT1 proc
CREATE OR ALTER PROC dbo.AddRowToT1
  @keycol INT,
  @col1   INT,
  @col2   VARCHAR(10)
AS

SET NOCOUNT ON;

BEGIN TRY

  INSERT INTO dbo.T1(keycol, col1, col2)
    VALUES(@keycol, @col1, @col2);

END TRY
BEGIN CATCH

  EXEC dbo.PrintErrorInfo;

END CATCH;
GO

-- test proc
EXEC dbo.AddRowToT1
  @keycol = 1,
  @col1 = -10,
  @col2 = 'AAA';
GO

---------------------------------------------------------------------
-- The THROW and RAISERROR commands
---------------------------------------------------------------------

---------------------------------------------------------------------
-- The THROW command
---------------------------------------------------------------------

-- THROW without parameters
CREATE OR ALTER PROC dbo.Divide
  @dividend AS INT,
  @divisor  AS INT
AS

SET NOCOUNT ON;

BEGIN TRY

  SELECT @dividend / @divisor AS quotient, @dividend % @divisor AS remainder;
 
END TRY
BEGIN CATCH

  PRINT 'Error occurred when trying to compute the division '
    + CAST(@dividend AS VARCHAR(11)) + ' / ' + CAST(@divisor AS VARCHAR(11)) + '.';

  THROW;

  PRINT 'This doesn''nt execute.';

END CATCH;
GO

-- test proc with valid inputs
EXEC dbo.Divide @dividend = 11, @divisor = 2;

-- test proc with invalid inputs
EXEC dbo.Divide @dividend = 11, @divisor = 0;
GO

-- example of ambiguity as column alias
CREATE OR ALTER PROC dbo.Divide
  @dividend AS INT,
  @divisor  AS INT
AS

SET NOCOUNT ON;

BEGIN TRY

  SELECT @dividend / @divisor AS quotient, @dividend % @divisor AS remainder;
 
END TRY
BEGIN CATCH

  SELECT 'What comes next is an alias'

  THROW;

END CATCH;
GO

EXEC dbo.Divide @dividend = 11, @divisor = 0;
GO

-- example of ambiguity as transaction marker
CREATE OR ALTER PROC dbo.Divide
  @dividend AS INT,
  @divisor  AS INT
AS

SET NOCOUNT ON;

BEGIN TRY

  SELECT @dividend / @divisor AS quotient, @dividend % @divisor AS remainder;
 
END TRY
BEGIN CATCH

  IF @@TRANCOUNT > 0 ROLLBACK TRAN

  THROW;

END CATCH;
GO

EXEC dbo.Divide @dividend = 11, @divisor = 0;
GO

-- execute from transaction
BEGIN TRAN;

EXEC dbo.Divide @dividend = 11, @divisor = 0;

PRINT '@@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
GO

-- make sure to roll the transaction back
ROLLBACK TRAN;

-- THROW with parameters
THROW 50000, 'This is a user-defined error.', 1;
GO

-- with variable
DECLARE @msg AS NVARCHAR(2048) =
  'This is a user-define error that occurred on ' + CONVERT(CHAR(10), SYSDATETIME(), 121) + '.';

THROW 50000, @msg, 1;
GO

-- with FORMATMESSAGE
DECLARE @msg AS NVARCHAR(2048) =
  FORMATMESSAGE('This is a user-define error that occurred on %s.',
    CONVERT(CHAR(10), SYSDATETIME(), 121));

THROW 50000, @msg, 1;
GO

-- TRHOW aborts the batch
THROW 50000, 'This is a user-defined error.', 1;
PRINT 'This code in the same batch doesn''t execute';
GO
PRINT 'This code in a different batch does execute.';

-- with XACT_ABORT off, THROW doesn't abort transaction
SET XACT_ABORT OFF;

BEGIN TRAN;

THROW 50000, 'Hello from THROW.', 1;
PRINT 'This doesn''t execute.';
GO

PRINT 'New batch... @@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
IF @@TRANCOUNT > 0
  ROLLBACK TRAN;
GO

-- with XACT_ABORT on, THROW aborts transaction
SET XACT_ABORT ON;

BEGIN TRAN;

THROW 50000, 'Hello from THROW.', 1;
PRINT 'This doesn''t execute.';
GO

PRINT 'New batch... @@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';
IF @@TRANCOUNT > 0
  ROLLBACK TRAN;
GO

---------------------------------------------------------------------
-- The RAISERROR command
---------------------------------------------------------------------

-- simple example for RAISERROR command
RAISERROR( 'This is a user-define error with a string parameter %s and an integer parameter %d.', 16, 1, 'ABC', 123 );

-- message with severity 0
RAISERROR( 'This is a message with severity 0.', 0, 1 );

-- message with severity 1 to 9
RAISERROR( 'This is a message with severity 1 to 9.', 1, 1 );

-- using NOWAIT
RAISERROR( 'First message.', 0, 1 ) WITH NOWAIT;
WAITFOR DELAY '00:00:05';
RAISERROR( 'Second message.', 0, 1 ) WITH NOWAIT;

-- without NOWAIT
RAISERROR( 'First message.', 0, 1 );
WAITFOR DELAY '00:00:05';
RAISERROR( 'Second message.', 0, 1 );

-- severity 20 using LOG
RAISERROR( 'This is a message with severity 20.', 20, 1 ) WITH LOG;

-- RAISERROR doesn't terminate the batch,
-- nor does it abort the transaction irrespective of the state of XACT_ABORT
SET XACT_ABORT ON;

BEGIN TRAN;

RAISERROR( 'This is a user-defined error.', 16, 1 );
PRINT 'This code in the same batch executes. @@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

IF @@TRANCOUNT > 0
  ROLLBACK TRAN;
GO

---------------------------------------------------------------------
-- Error handling with transactions
---------------------------------------------------------------------

-- doesn't abort batch and doesn't abort transaction
SET XACT_ABORT OFF;

BEGIN TRAN;

DECLARE @i AS INT = 10/0;
PRINT 'Batch wasn''t aborted.';
GO

PRINT '@@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

IF @@TRANCOUNT > 0
  ROLLBACK TRAN;
GO

-- aborts batch and transaction
BEGIN TRAN;

DECLARE @i AS INT = CAST('1,759' AS INT);
PRINT 'Batch wasn''t aborted.';
GO

PRINT '@@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

IF @@TRANCOUNT > 0
  ROLLBACK TRAN;
GO

-- with XACT_ABORT turned on
SET XACT_ABORT ON;

BEGIN TRAN;

DECLARE @i AS INT = 10/0;
PRINT 'Batch wasn''t aborted.';
GO

PRINT '@@TRANCOUNT is ' + CAST(@@TRANCOUNT AS VARCHAR(10)) + '.';

IF @@TRANCOUNT > 0
  ROLLBACK TRAN;
GO

-- open and committable state
SET XACT_ABORT OFF;

BEGIN TRY

  BEGIN TRAN;

  DECLARE @i AS INT = 10/0;
  -- normally there would be work here that warrants a transaction

  COMMIT TRAN;

END TRY
BEGIN CATCH

  PRINT
    CASE XACT_STATE()
      WHEN  0 THEN 'No open transaction.'
      WHEN  1 THEN 'Transaction is open and committable.'
      WHEN -1 THEN 'Transaction is doomed.'
    END;

  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;

END CATCH;
GO

-- doomed state
SET XACT_ABORT OFF;

BEGIN TRY

  BEGIN TRAN;

  DECLARE @i AS INT = CAST('1,759' AS INT);
  -- normally there would be work here that warrants a transaction

  COMMIT TRAN;

END TRY
BEGIN CATCH

  PRINT
    CASE XACT_STATE()
      WHEN  0 THEN 'No open transaction.'
      WHEN  1 THEN 'Transaction is open and committable.'
      WHEN -1 THEN 'Transaction is doomed.'
    END;

  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;

END CATCH;
GO

-- AddOrder procedure with error handling
CREATE OR ALTER PROC dbo.AddOrder
  @custid         AS INT,
  @empid          AS INT,
  @orderdate      AS DATE,
  @requireddate   AS DATE,
  @shippeddate    AS DATE,
  @shipperid      AS INT,
  @freight        AS MONEY,
  @shipname       AS NVARCHAR(40),
  @shipaddress    AS NVARCHAR(60),
  @shipcity       AS NVARCHAR(15),
  @shipregion     AS NVARCHAR(15),
  @shippostalcode AS NVARCHAR(10),
  @shipcountry    AS NVARCHAR(15),
  @OrderLines     AS dbo.OrderLines READONLY,
  @neworderid     AS INT OUT
AS

SET XACT_ABORT, NOCOUNT ON;

BEGIN TRY

BEGIN TRAN;

  -- add order header
  INSERT INTO Sales.Orders
      (custid, empid, orderdate, requireddate, shippeddate, 
       shipperid, freight, shipname, shipaddress, shipcity,
       shippostalcode, shipcountry)
    VALUES
      (@custid, @empid, @orderdate, @requireddate, @shippeddate, 
       @shipperid, @freight, @shipname, @shipaddress, @shipcity,
       @shippostalcode, @shipcountry);

  SET @neworderid = SCOPE_IDENTITY();

  -- add order lines
  INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
    SELECT @neworderid, productid, unitprice, qty, discount
    FROM @OrderLines;

  COMMIT TRAN;

END TRY
BEGIN CATCH
  
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;

  THROW;

END CATCH;
GO

-- clenup
DELETE FROM Sales.OrderDetails WHERE orderid > 11077;
DELETE FROM Sales.Orders WHERE orderid > 11077;
DBCC CHECKIDENT('Sales.Orders', RESEED, 11077);
DROP PROC IF EXISTS dbo.AddRowToT1, dbo.OuterProc, dbo.InnerProc,
  dbo.PrintErrorInfo, dbo.Divide, dbo.AddOrder, dbo.Proc1;
DROP TABLE IF EXISTS dbo.T1, dbo.ErrorLog;
