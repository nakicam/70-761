---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 2 - Query Data with Advanced Transact-SQL Components
-- Skill 2.1: Query data by using subqueries and APPLY
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Subqueries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Self-Contained Subqueries
---------------------------------------------------------------------

-- scalar subqueries
-- products with minimum price
USE TSQLV4;

SELECT productid, productname, unitprice
FROM Production.Products
WHERE unitprice =
  (SELECT MIN(unitprice)
   FROM Production.Products);
   
-- multi-valued subqieries
-- products supplied by suppliers from Japan
SELECT productid, productname, unitprice
FROM Production.Products
WHERE supplierid IN
  (SELECT supplierid
   FROM Production.Suppliers
   WHERE country = N'Japan');

-- ALL
-- alternative solution for products with minimum price
SELECT productid, productname, unitprice
FROM Production.Products
WHERE unitprice <= ALL (SELECT unitprice FROM Production.Products);

-- ANY / SOME
-- products with price that is not the minimum
SELECT productid, productname, unitprice
FROM Production.Products
WHERE unitprice > ANY (SELECT unitprice FROM Production.Products);

---------------------------------------------------------------------
-- Correlated subqueries
---------------------------------------------------------------------

-- products with minimum unitprice per category
SELECT categoryid, productid, productname, unitprice
FROM Production.Products AS P1
WHERE unitprice =
  (SELECT MIN(unitprice)
   FROM Production.Products AS P2
   WHERE P2.categoryid = P1.categoryid);

-- customers who placed an order on February 12, 2016
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
  (SELECT *
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid
     AND O.orderdate = '20160212');

-- customers who did not place an order on February 12, 2016
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
  (SELECT *
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid
     AND O.orderdate = '20160212');

---------------------------------------------------------------------
-- Optimization of subqueries versus joins
---------------------------------------------------------------------

-- compute for each order the percent of the current freight value
-- out of customer total, and difference from average

-- index to support queries
CREATE INDEX idx_cid_i_frt_oid
  ON Sales.Orders(custid) INCLUDE(freight, orderid);

-- Each subquery involves separate access to data
SELECT orderid, custid, freight,
  freight / ( SELECT SUM(O2.freight)
              FROM Sales.Orders AS O2
              WHERE O2.custid = O1.custid ) AS pctcust,
  freight - ( SELECT AVG(O3.freight)
              FROM Sales.Orders AS O3
              WHERE O3.custid = O1.custid ) AS diffavgcust
FROM Sales.Orders AS O1;

-- With join only one access to data to compute all aggregates
SELECT O.orderid, O.custid, O.freight,
  freight / totalfreight AS pctcust,
  freight - avgfreight AS diffavgcust
FROM Sales.Orders AS O
  INNER JOIN ( SELECT custid, SUM(freight) AS totalfreight, AVG(freight) AS avgfreight
               FROM Sales.Orders
               GROUP BY custid ) AS A
    ON O.custid = A.custid;

-- remove index
DROP INDEX idx_cid_i_frt_oid ON Sales.Orders;

-- identify shippers who didn't handle any orders yet

-- add row
INSERT INTO Sales.Shippers(companyname, phone)
  VALUES('Shipper XYZ', '(123) 456-7890');

-- with subquery
SELECT S.shipperid
FROM Sales.Shippers AS S
WHERE NOT EXISTS
  (SELECT *
   FROM Sales.Orders AS O
   WHERE O.shipperid = S.shipperid);

-- with join
SELECT S.shipperid 
FROM Sales.Shippers AS S
  LEFT OUTER JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
WHERE O.orderid IS NULL;

-- Delete new shipper row
DELETE FROM Sales.Shippers WHERE shipperid > 3;

---------------------------------------------------------------------
-- The APPLY operator
---------------------------------------------------------------------

-- add a supplier from Japan
INSERT INTO Production.Suppliers
  (companyname, contactname, contacttitle, address, city, postalcode, country, phone)
  VALUES(N'Supplier XYZ', N'Jiru', N'Head of Security', N'42 Sekimai Musashino-shi',
         N'Tokyo', N'01759', N'Japan', N'(02) 4311-2609');

-- two products with lowest unit prices for given supplier
SELECT TOP (2) productid, productname, unitprice
FROM Production.Products
WHERE supplierid = 1
ORDER BY unitprice, productid;

-- CROSS APPLY
-- two products with lowest unit prices for each supplier from Japan
-- exclude suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  CROSS APPLY (SELECT TOP (2) productid, productname, unitprice
               FROM Production.Products AS P
               WHERE P.supplierid = S.supplierid
               ORDER BY unitprice, productid) AS A
WHERE S.country = N'Japan';

-- OUTER APPLY
-- two products with lowest unit prices for each supplier from Japan
-- include suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  OUTER APPLY (SELECT TOP (2) productid, productname, unitprice
               FROM Production.Products AS P
               WHERE P.supplierid = S.supplierid
               ORDER BY unitprice, productid) AS A
WHERE S.country = N'Japan';

-- cleanup
DELETE FROM Production.Suppliers WHERE supplierid > 29;
