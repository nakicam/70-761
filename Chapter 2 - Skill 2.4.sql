---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 2 - Query Data with Advanced Transact-SQL Components
-- Skill 2.4: Query temporal data and non-relational data
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- System-versioned temporal tables
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Creating tables
---------------------------------------------------------------------

-- create Products table as a temporal table
USE TSQLV4;

CREATE TABLE dbo.Products
(
  productid   INT          NOT NULL
    CONSTRAINT PK_dboProducts PRIMARY KEY(productid),
  productname NVARCHAR(40) NOT NULL,
  supplierid  INT          NOT NULL,
  categoryid  INT          NOT NULL,
  unitprice   MONEY        NOT NULL,
-- below are additions related to temporal table
  validfrom   DATETIME2(3)
    GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
  validto     DATETIME2(3)
    GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,
  PERIOD FOR SYSTEM_TIME (validfrom, validto)
)
WITH ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.ProductsHistory ) );
GO

-- alter existing nontemporal table to be temporal
/*
BEGIN TRAN;

ALTER TABLE dbo.Products ADD
  validfrom DATETIME2(3) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL
    CONSTRAINT DFT_Products_validfrom DEFAULT('19000101'),
  validto DATETIME2(3) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL
    CONSTRAINT DFT_Products_validto DEFAULT('99991231 23:59:59.999'),
  PERIOD FOR SYSTEM_TIME (validfrom, validto);

ALTER TABLE dbo.Products
  SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.ProductsHistory ) );

ALTER TABLE dbo.Products DROP CONSTRAINT DFT_Products_validfrom, DFT_Products_validto;

COMMIT TRAN;
*/

-- alter temporal table
ALTER TABLE dbo.Products
  ADD discontinued BIT NOT NULL
    CONSTRAINT DFT_Products_discontinued DEFAULT(0);

-- remove column
ALTER TABLE dbo.Products
  DROP CONSTRAINT DFT_Products_discontinued;

ALTER TABLE dbo.Products
  DROP COLUMN discontinued;

---------------------------------------------------------------------
-- Modifying data
---------------------------------------------------------------------

-- add rows at 14:07 (UTC time zone)
INSERT INTO dbo.Products(productid, productname, supplierid, categoryid, unitprice)
  SELECT productid, productname, supplierid, categoryid, unitprice
  FROM Production.Products
  WHERE productid <= 10;

-- query data
SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products;

SELECT productid, unitprice, validfrom, validto
FROM dbo.ProductsHistory;

-- delete a row at 14:08
DELETE FROM dbo.Products
WHERE productid = 10;

-- update rows at 14:09
UPDATE dbo.Products
  SET unitprice *= 1.05
WHERE supplierid = 3;

-- query current table
SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products;

-- query history table
SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.ProductsHistory;

-- modifying data in a transaction uses transaction start time (14:10:43.470)
BEGIN TRAN;

PRINT CAST(SYSUTCDATETIME() AS DATETIME2(3));

UPDATE dbo.Products
  SET unitprice *= 0.95
WHERE productid = 1;

WAITFOR DELAY '00:00:05.000';

UPDATE dbo.Products
  SET unitprice *= 0.90
WHERE productid = 2;

WAITFOR DELAY '00:00:05.000';

UPDATE dbo.Products
  SET unitprice *= 0.85
WHERE productid = 3;

COMMIT TRAN;

-- query current table
SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products
WHERE productid IN (1, 2, 3);

-- multiple updates in the same transaction will result in zero length validity period
-- transaction start time is 14:11:38.113
BEGIN TRAN;

PRINT CAST(SYSUTCDATETIME() AS DATETIME2(3));

UPDATE dbo.Products
  SET unitprice = 1.0
WHERE productid = 9;

WAITFOR DELAY '00:00:05.000';

UPDATE dbo.Products
  SET unitprice = 2.0
WHERE productid = 9;

WAITFOR DELAY '00:00:05.000';

UPDATE dbo.Products
  SET unitprice = 3.0
WHERE productid = 9;

COMMIT TRAN;

-- query current table
SELECT productid, unitprice, validfrom, validto
FROM dbo.Products
WHERE productid = 9;

-- query history table
SELECT productid, unitprice, validfrom, validto
FROM dbo.ProductsHistory
WHERE productid = 9;

---------------------------------------------------------------------
-- Querying Data
---------------------------------------------------------------------

-- code to populate the tables with the same sample data as in my examples
USE TSQLV4;

-- drop tables if exist
IF OBJECT_ID(N'dbo.Products', N'U') IS NOT NULL
BEGIN
  IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Products', N'U'), N'TableTemporalType') = 2
    ALTER TABLE dbo.Products SET ( SYSTEM_VERSIONING = OFF );
  DROP TABLE IF EXISTS dbo.ProductsHistory, dbo.Products;
END;
GO

-- create and populate Products table
CREATE TABLE dbo.Products
(
  productid   INT          NOT NULL
    CONSTRAINT PK_dboProducts PRIMARY KEY(productid),
  productname NVARCHAR(40) NOT NULL,
  supplierid  INT          NOT NULL,
  categoryid  INT          NOT NULL,
  unitprice   MONEY        NOT NULL,
  validfrom   DATETIME2(3) NOT NULL,
  validto     DATETIME2(3) NOT NULL
);

INSERT INTO dbo.Products
  (productid, productname, supplierid, categoryid, unitprice, validfrom, validto)
VALUES
  (1, 'Product HHYDP', 1, 1, 17.10, '20161101 14:10:43.470', '99991231 23:59:59.999'),
  (2, 'Product RECZE', 1, 1, 17.10, '20161101 14:10:43.470', '99991231 23:59:59.999'),
  (3, 'Product IMEHJ', 1, 2,  8.50, '20161101 14:10:43.470', '99991231 23:59:59.999'),
  (4, 'Product KSBRM', 2, 2, 22.00, '20161101 14:07:26.263', '99991231 23:59:59.999'),
  (5, 'Product EPEIM', 2, 2, 21.35, '20161101 14:07:26.263', '99991231 23:59:59.999'),
  (6, 'Product VAIIV', 3, 2, 26.25, '20161101 14:09:18.584', '99991231 23:59:59.999'),
  (7, 'Product HMLNI', 3, 7, 31.50, '20161101 14:09:18.584', '99991231 23:59:59.999'),
  (8, 'Product WVJFP', 3, 2, 42.00, '20161101 14:09:18.584', '99991231 23:59:59.999'),
  (9, 'Product AOZBW', 4, 6,  3.00, '20161101 14:11:38.113', '99991231 23:59:59.999');

-- create and populate ProductsHistory table
CREATE TABLE dbo.ProductsHistory
(
  productid   INT          NOT NULL,
  productname NVARCHAR(40) NOT NULL,
  supplierid  INT          NOT NULL,
  categoryid  INT          NOT NULL,
  unitprice   MONEY        NOT NULL,
  validfrom   DATETIME2(3) NOT NULL,
  validto     DATETIME2(3) NOT NULL,
  INDEX ix_ProductsHistory CLUSTERED(validto, validfrom)
    WITH (DATA_COMPRESSION = PAGE)
);

INSERT INTO dbo.ProductsHistory
  (productid, productname, supplierid, categoryid, unitprice, validfrom, validto)
VALUES
  ( 1, 'Product HHYDP', 1, 1, 18.00, '20161101 14:07:26.263', '20161101 14:10:43.470'),
  ( 2, 'Product RECZE', 1, 1, 19.00, '20161101 14:07:26.263', '20161101 14:10:43.470'),
  ( 3, 'Product IMEHJ', 1, 2, 10.00, '20161101 14:07:26.263', '20161101 14:10:43.470'),
  ( 6, 'Product VAIIV', 3, 2, 25.00, '20161101 14:07:26.263', '20161101 14:09:18.584'),
  ( 7, 'Product HMLNI', 3, 7, 30.00, '20161101 14:07:26.263', '20161101 14:09:18.584'),
  ( 8, 'Product WVJFP', 3, 2, 40.00, '20161101 14:07:26.263', '20161101 14:09:18.584'),
  ( 9, 'Product AOZBW', 4, 6, 97.00, '20161101 14:07:26.263', '20161101 14:11:38.113'),
  ( 9, 'Product AOZBW', 4, 6,  1.00, '20161101 14:11:38.113', '20161101 14:11:38.113'),
  ( 9, 'Product AOZBW', 4, 6,  2.00, '20161101 14:11:38.113', '20161101 14:11:38.113'),
  (10, 'Product YHXGE', 4, 8, 31.00, '20161101 14:07:26.263', '20161101 14:08:41.758');

-- enable system versioning
ALTER TABLE dbo.Products ADD PERIOD FOR SYSTEM_TIME (validfrom, validto);

ALTER TABLE dbo.Products ALTER COLUMN validfrom ADD HIDDEN;
ALTER TABLE dbo.Products ALTER COLUMN validto ADD HIDDEN;

ALTER TABLE dbo.Products
  SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.ProductsHistory ) );

-- query current table
SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products;

-- query history table
SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.ProductsHistory;

-- FOR SYSTEM_TIME AS OF @dt

-- following query returns an empty result
SELECT productid, supplierid, unitprice
FROM dbo.Products FOR SYSTEM_TIME AS OF '20161101 14:06:00.000';

-- following query returns state after first insert, which was submitted at 14:07:26.263
SELECT productid, supplierid, unitprice
FROM dbo.Products FOR SYSTEM_TIME AS OF '20161101 14:07:55.000';

-- can query different points in time
SELECT T1.productid, T1.productname,
  CAST( (T2.unitprice / T1.unitprice - 1.0) * 100.0 AS NUMERIC(10, 2) ) AS pct
FROM dbo.Products FOR SYSTEM_TIME AS OF '20161101 14:08:55.000' AS T1
  INNER JOIN dbo.Products FOR SYSTEM_TIME AS OF '20161101 14:10:55.000' AS T2
    ON T1.productid = T2.productid
   AND T2.unitprice > T1.unitprice;

-- FOR SYSTEM_TIME FROM @start TO @end 

SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products
  FOR SYSTEM_TIME FROM '20161101 14:00:00.000' TO '20161101 14:11:38.113'
WHERE productid = 9;

-- FOR SYSTEM_TIME BETWEEN @start AND @end 

SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products
  FOR SYSTEM_TIME BETWEEN '20161101 14:00:00.000' AND '20161101 14:11:38.113'
WHERE productid = 9;

-- FOR SYSTEM_TIME CONTAINED IN(@start, @end)

SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products
  FOR SYSTEM_TIME CONTAINED IN('20161101 14:07:00.000', '20161101 14:10:00.000');

-- add constraint to current table
ALTER TABLE dbo.Products
  ADD CONSTRAINT CHK_Products_validto
    CHECK (validto = '99991231 23:59:59.999');

-- FOR SYSTEM_TIME ALL
SELECT productid, supplierid, unitprice, validfrom, validto
FROM dbo.Products FOR SYSTEM_TIME ALL
ORDER BY productid, validfrom, validto;

-- to see start and end times in specific time zone instead of UTC
SELECT productid, supplierid, unitprice, 
  validfrom AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS validfrom,
  CASE
    WHEN validto = '99991231 23:59:59.999'
      THEN validto AT TIME ZONE 'UTC'
    ELSE validto AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'
  END AS validto
FROM dbo.Products FOR SYSTEM_TIME ALL
ORDER BY productid, validfrom, validto;

-- Run the following code for cleanup
IF OBJECT_ID(N'dbo.Products', N'U') IS NOT NULL
BEGIN
  IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Products', N'U'), N'TableTemporalType') = 2
    ALTER TABLE dbo.Products SET ( SYSTEM_VERSIONING = OFF );
  DROP TABLE IF EXISTS dbo.ProductsHistory, dbo.Products;
END;

---------------------------------------------------------------------
-- Query and output XML data
---------------------------------------------------------------------

USE TSQLV4;

---------------------------------------------------------------------
-- Producing and using XML in queries
---------------------------------------------------------------------

-- Create XML example with FOR XML AUTO option, atttribute-centric
-- This query is used to produce the demo XML document at the beginning of the XML section
SELECT Customer.custid, Customer.companyname, 
  [Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
  INNER JOIN Sales.Orders AS [Order]
    ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
  AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML AUTO, ROOT('CustomersOrders');

-- FOR XML RAW
-- Basic
SELECT Customer.custid, Customer.companyname, 
  [Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
  INNER JOIN Sales.Orders AS [Order]
    ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
  AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW;

-- FOR XML AUTO
-- Element-centric, with namespace, root element
WITH XMLNAMESPACES('ER70761-CustomersOrders' AS co)
SELECT [co:Customer].custid AS [co:custid], 
  [co:Customer].companyname AS [co:companyname], 
  [co:Order].orderid AS [co:orderid], 
  [co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
  INNER JOIN Sales.Orders AS [co:Order]
    ON [co:Customer].custid = [co:Order].custid
WHERE [co:Customer].custid <= 2
  AND [co:Order].orderid %2 = 0
ORDER BY [co:Customer].custid, [co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');

-- OPENXML
-- Rowset description in WITH clause
DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(1000);
SET @XmlDocument = N'
<CustomersOrders>
  <Customer custid="1">
    <companyname>Customer NRZBB</companyname>
    <Order orderid="10692">
      <orderdate>2015-10-03T00:00:00</orderdate>
    </Order>
    <Order orderid="10702">
      <orderdate>2015-10-13T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2016-03-16T00:00:00</orderdate>
    </Order>
  </Customer>
  <Customer custid="2">
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2014-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10926">
      <orderdate>2016-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';
-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;
-- Attribute- and element-centric mapping
-- Combining flag 8 with flags 1 and 2
SELECT *
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',11)
     WITH (custid INT,
           companyname NVARCHAR(40));
-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;
GO

---------------------------------------------------------------------
-- Querying XML data with XQuery
---------------------------------------------------------------------

-- XQuery with FLWOR Expressions
DECLARE @x AS XML = N'
<CustomersOrders>
  <Customer custid="1">
    <!-- Comment 111 -->
    <companyname>Customer NRZBB</companyname>
    <Order orderid="10692">
      <orderdate>2015-10-03T00:00:00</orderdate>
    </Order>
    <Order orderid="10702">
      <orderdate>2015-10-13T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2016-03-16T00:00:00</orderdate>
    </Order>
  </Customer>
  <Customer custid="2">
    <!-- Comment 222 -->  
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2014-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2016-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';
SELECT @x.query('for $i in CustomersOrders/Customer/Order
                 let $j := $i/orderdate
                 where $i/@orderid < 10900
                 order by ($j)[1]
                 return 
                 <Order-orderid-element>
                  <orderid>{data($i/@orderid)}</orderid>
                  {$j}
                 </Order-orderid-element>')
       AS [Filtered, sorted and reformatted orders with let clause];
GO

---------------------------------------------------------------------
-- The XML data type
---------------------------------------------------------------------

-- Using the XML data type for dynamic schema
ALTER TABLE Production.Products
 ADD additionalattributes XML NULL;
GO

-- Auxiliary tables
CREATE TABLE dbo.Beverages(percentvitaminsRDA INT); 
CREATE TABLE dbo.Condiments(shortdescription NVARCHAR(50)); 
GO 
-- Store the schemas in a variable and create the collection 
DECLARE @mySchema AS NVARCHAR(MAX) = N''; 
SET @mySchema +=
  (SELECT * 
   FROM Beverages 
   FOR XML AUTO, ELEMENTS, XMLSCHEMA('Beverages')); 
SET @mySchema +=
  (SELECT * 
   FROM Condiments 
   FOR XML AUTO, ELEMENTS, XMLSCHEMA('Condiments')); 
SELECT CAST(@mySchema AS XML);
CREATE XML SCHEMA COLLECTION dbo.ProductsAdditionalAttributes AS @mySchema; 
GO 
-- Drop auxiliary tables 
DROP TABLE dbo.Beverages, dbo.Condiments;
GO

-- Validate XML instances
ALTER TABLE Production.Products 
  ALTER COLUMN additionalattributes
   XML(dbo.ProductsAdditionalAttributes);
GO

-- Function to retrieve the namespace
CREATE FUNCTION dbo.GetNamespace(@chkcol AS XML)
 RETURNS NVARCHAR(15)
AS
BEGIN
 RETURN @chkcol.value('namespace-uri((/*)[1])','NVARCHAR(15)');
END;
GO
-- Function to retrieve the category name
CREATE FUNCTION dbo.GetCategoryName(@catid AS INT)
 RETURNS NVARCHAR(15)
AS
BEGIN
 RETURN 
  (SELECT categoryname 
   FROM Production.Categories
   WHERE categoryid = @catid);
END;
GO
-- Add the constraint
ALTER TABLE Production.Products ADD CONSTRAINT ck_Namespace
 CHECK (dbo.GetNamespace(additionalattributes) = 
        dbo.GetCategoryName(categoryid));
GO

-- Valid Data
-- Beverage
UPDATE Production.Products 
   SET additionalattributes = N'
<Beverages xmlns="Beverages"> 
  <percentvitaminsRDA>27</percentvitaminsRDA> 
</Beverages>'
WHERE productid = 1; 
-- Condiment
UPDATE Production.Products 
   SET additionalattributes = N'
<Condiments xmlns="Condiments"> 
  <shortdescription>very sweet</shortdescription> 
</Condiments>'
WHERE productid = 3; 
GO

-- Invalid Data
-- String instead of int
UPDATE Production.Products 
   SET additionalattributes = N'
<Beverages xmlns="Beverages"> 
  <percentvitaminsRDA>twenty seven</percentvitaminsRDA> 
</Beverages>'
WHERE productid = 1; 
-- Wrong namespace
UPDATE Production.Products 
   SET additionalattributes = N'
<Condiments xmlns="Condiments"> 
  <shortdescription>very sweet</shortdescription> 
</Condiments>'
WHERE productid = 2; 
-- Wrong element
UPDATE Production.Products 
   SET additionalattributes = N'
<Condiments xmlns="Condiments"> 
  <unknownelement>very sweet</unknownelement> 
</Condiments>'
WHERE productid = 3;
GO

-- Check the data
SELECT productid, productname, additionalattributes
FROM Production.Products
WHERE productid <= 3;
GO

-- Clean up
ALTER TABLE Production.Products
 DROP CONSTRAINT ck_Namespace;
ALTER TABLE Production.Products
 DROP COLUMN additionalattributes;
DROP XML SCHEMA COLLECTION dbo.ProductsAdditionalAttributes;
DROP FUNCTION dbo.GetNamespace;
DROP FUNCTION dbo.GetCategoryName;
GO

---------------------------------------------------------------------
-- Query and output JSON data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Producing JSON output from queries
---------------------------------------------------------------------

USE TSQLV4;
GO

-- Create JSON example with FOR JSON AUTO option
-- This query is used to produce the demo JSON document
SELECT Customer.custid, Customer.companyname, 
  [Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
  INNER JOIN Sales.Orders AS [Order]
    ON Customer.custid = [Order].custid
WHERE Customer.custid <= 2
  AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR JSON AUTO;

-- Format the results with JSON formatter
-- e.g., https://jsonformatter.curiousconcept.com/
/* Formatted result
[
   {
      "custid":1,
      "companyname":"Customer NRZBB",
      "Order":[
         {
            "orderid":10692,
            "orderdate":"2015-10-03"
         },
         {
            "orderid":10702,
            "orderdate":"2015-10-13"
         },
         {
            "orderid":10952,
            "orderdate":"2016-03-16"
         }
      ]
   },
   {
      "custid":2,
      "companyname":"Customer MLTDN",
      "Order":[
         {
            "orderid":10308,
            "orderdate":"2014-09-18"
         },
         {
            "orderid":10926,
            "orderdate":"2016-03-04"
         }
      ]
   }
]
*/

-- FOR JSON PATH - simple
SELECT TOP (2) custid, companyname, contactname
FROM Sales.Customers
ORDER BY custid
FOR JSON PATH;

-- Using dot
SELECT custid AS [CustomerId], 
  companyname AS [Company], 
  contactname AS [Contact.Name]
FROM Sales.Customers
WHERE custid = 1
FOR JSON PATH;

-- Dot aliases with multiple tables
SELECT c.custid AS [Customer.Id], 
  c.companyname AS [Customer.Name], 
  o.orderid AS [Order.Id], 
  o.orderdate AS [Order.Date]
FROM Sales.Customers AS c
  INNER JOIN Sales.Orders AS o
    ON c.custid = o.custid
WHERE c.custid = 1
  AND o.orderid = 10692
ORDER BY c.custid, o.orderid
FOR JSON PATH;

-- Dot aliases with multiple tables, orders nested
SELECT c.custid AS [Customer.Id], 
  c.companyname AS [Customer.Name], 
  o.orderid AS [Customer.Order.Id], 
  o.orderdate AS [Customer.Order.Date]
FROM Sales.Customers AS c
  INNER JOIN Sales.Orders AS o
    ON c.custid = o.custid
WHERE c.custid = 1
  AND o.orderid = 10692
ORDER BY c.custid, o.orderid
FOR JSON PATH;

-- Remove brackets
SELECT c.custid AS [Customer.Id], 
  c.companyname AS [Customer.Name], 
  o.orderid AS [Customer.Order.Id], 
  o.orderdate AS [Customer.Order.Date]
FROM Sales.Customers AS c
  INNER JOIN Sales.Orders AS o
    ON c.custid = o.custid
WHERE c.custid = 1
  AND o.orderid = 10692
ORDER BY c.custid, o.orderid
FOR JSON PATH,
    WITHOUT_ARRAY_WRAPPER;

-- Add a root element
SELECT c.custid AS [Customer.Id], 
  c.companyname AS [Customer.Name], 
  o.orderid AS [Customer.Order.Id], 
  o.orderdate AS [Customer.Order.Date]
FROM Sales.Customers AS c
  INNER JOIN Sales.Orders AS o
    ON c.custid = o.custid
WHERE c.custid = 1
  AND o.orderid = 10692
ORDER BY c.custid, o.orderid
FOR JSON PATH,
    ROOT('Customer 1');

-- Add a null
SELECT c.custid AS [Customer.Id], 
  c.companyname AS [Customer.Name], 
  o.orderid AS [Customer.Order.Id], 
  o.orderdate AS [Customer.Order.Date],
  NULL AS [Customer.Order.Delivery]
FROM Sales.Customers AS c
  INNER JOIN Sales.Orders AS o
    ON c.custid = o.custid
WHERE c.custid = 1
  AND o.orderid = 10692
ORDER BY c.custid, o.orderid
FOR JSON PATH,
    WITHOUT_ARRAY_WRAPPER,
    INCLUDE_NULL_VALUES;

---------------------------------------------------------------------
-- Convert JSON data to tabular format
---------------------------------------------------------------------

-- OPENJSON with implicit schema
DECLARE @json AS NVARCHAR(MAX) = N'
{ 
   "Customer":{ 
      "Id":1, 
      "Name":"Customer NRZBB",
      "Order":{ 
         "Id":10692, 
         "Date":"2015-10-03",
         "Delivery":null
      }
   }
}';
SELECT *
FROM OPENJSON(@json);
GO

-- OPENJSON with path
DECLARE @json AS NVARCHAR(MAX) = N'
{ 
   "Customer":{ 
      "Id":1, 
      "Name":"Customer NRZBB",
      "Order":{ 
         "Id":10692, 
         "Date":"2015-10-03",
         "Delivery":null
      }
   }
}';
SELECT *
FROM OPENJSON(@json,'$.Customer');
GO

-- lax and strict mode
DECLARE @json AS NVARCHAR(MAX) = N'
{ 
  "Customer":{ 
      "Name":"Customer NRZBB"
      }
}';
SELECT *
FROM OPENJSON(@json,'lax $.Buyer');
SELECT *
FROM OPENJSON(@json,'strict $.Buyer');
GO

-- OPENJSON with explicit schema
DECLARE @json AS NVARCHAR(MAX) = N'
{ 
   "Customer":{ 
      "Id":1, 
      "Name":"Customer NRZBB",
      "Order":{ 
         "Id":10692, 
         "Date":"2015-10-03",
         "Delivery":null
      }
   }
}';
SELECT *
FROM OPENJSON(@json)
WITH
(
 CustomerId   INT           '$.Customer.Id',
 CustomerName NVARCHAR(20)  '$.Customer.Name',
 Orders       NVARCHAR(MAX) '$.Customer.Order' AS JSON
);
GO

-- JSON_VALUE and JSON_QUERY
DECLARE @json AS NVARCHAR(MAX) = N'
{ 
   "Customer":{ 
      "Id":1, 
      "Name":"Customer NRZBB",
      "Order":{ 
         "Id":10692, 
         "Date":"2015-10-03",
         "Delivery":null
      }
   }
}';
SELECT JSON_VALUE(@json, '$.Customer.Id') AS CustomerId,
 JSON_VALUE(@json, '$.Customer.Name') AS CustomerName,
 JSON_QUERY(@json, '$.Customer.Order') AS Orders;
GO

-- JSON_MODIFY
DECLARE @json AS NVARCHAR(MAX) = N'
{ 
   "Customer":{ 
      "Id":1, 
      "Name":"Customer NRZBB",
      "Order":{ 
         "Id":10692, 
         "Date":"2015-10-03",
         "Delivery":null
      }
   }
}'; 
-- Update name  
SET @json = JSON_MODIFY(@json, '$.Customer.Name', 'Modified first name'); 
-- Delete Id  
SET @json = JSON_MODIFY(@json, '$.Customer.Id', NULL)  
-- Insert last name  
SET @json = JSON_MODIFY(@json, '$.Customer.LastName', 'Added last name')  
PRINT @json;
GO

-- ISJSON
SELECT ISJSON ('str') AS s1,  ISJSON ('') AS s2, 
  ISJSON ('{}') AS s3,  ISJSON ('{"a"}') AS s4, 
  ISJSON ('{"a":1}') AS s5;
GO
