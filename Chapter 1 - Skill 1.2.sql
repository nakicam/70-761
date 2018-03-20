---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 1 - Manage Data with Transact-SQL
-- Skill 1.2: Query multiple tables by using joins
-- © Itzik Ben-Gan
---------------------------------------------------------------------

-- add a row to the suppliers table
USE TSQLV4;

INSERT INTO Production.Suppliers
  (companyname, contactname, contacttitle, address, city, postalcode, country, phone)
  VALUES(N'Supplier XYZ', N'Jiru', N'Head of Security', N'42 Sekimai Musashino-shi',
         N'Tokyo', N'01759', N'Japan', N'(02) 4311-2609');

---------------------------------------------------------------------
-- Cross Joins
---------------------------------------------------------------------

-- a cross join returning a row for each day of the week
-- and shift number out of three
SELECT D.n AS theday, S.n AS shiftno  
FROM dbo.Nums AS D
  CROSS JOIN dbo.Nums AS S
WHERE D.n <= 7
  AND S.N <= 3
ORDER BY theday, shiftno;

---------------------------------------------------------------------
-- Inner Joins
---------------------------------------------------------------------

-- suppliers from Japan and products they supply
-- suppliers without products not included
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  INNER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

-- same meaning
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  INNER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
    AND S.country = N'Japan';

-- employees and their managers
-- employee without manager (CEO) not included
SELECT E.empid,
  E.firstname + N' ' + E.lastname AS emp,
  M.firstname + N' ' + M.lastname AS mgr
FROM HR.Employees AS E
  INNER JOIN HR.Employees AS M
    ON E.mgrid = M.empid;

---------------------------------------------------------------------
-- Outer Joins
---------------------------------------------------------------------

-- suppliers from Japan and products they supply
-- suppliers without products included
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

-- return all suppliers
-- show products for only suppliers from Japan
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
   AND S.country = N'Japan';

---------------------------------------------------------------------
-- Queries with composite joins and NULLs in join columns
---------------------------------------------------------------------

-- employees and their managers
-- employee without manager (CEO) included
SELECT E.empid,
  E.firstname + N' ' + E.lastname AS emp,
  M.firstname + N' ' + M.lastname AS mgr
FROM HR.Employees AS E
  LEFT OUTER JOIN HR.Employees AS M
    ON E.mgrid = M.empid;

-- sample data for composite join example
DROP TABLE IF EXISTS dbo.EmpLocations;

SELECT country, region, city, COUNT(*) AS numemps
INTO dbo.EmpLocations
FROM HR.Employees
GROUP BY country, region, city;

ALTER TABLE dbo.EmpLocations ADD CONSTRAINT UNQ_EmpLocations
  UNIQUE CLUSTERED(country, region, city);

DROP TABLE IF EXISTS dbo.CustLocations;

SELECT country, region, city, COUNT(*) AS numcusts
INTO dbo.CustLocations
FROM Sales.Customers
GROUP BY country, region, city;

ALTER TABLE dbo.CustLocations ADD CONSTRAINT UNQ_CustLocations
  UNIQUE CLUSTERED(country, region, city);

-- query EmpLocations table
SELECT country, region, city, numemps
FROM dbo.EmpLocations;

-- query CustLocations table
SELECT country, region, city, numcusts
FROM dbo.CustLocations;

-- join tables, incorrect handling of NULLs
SELECT EL.country, EL.region, EL.city, EL.numemps, CL.numcusts
FROM dbo.EmpLocations AS EL
  INNER JOIN dbo.CustLocations AS CL
    ON EL.country = CL.country
    AND EL.region = CL.region
    AND EL.city = CL.city;

-- correct handling of NULLs, but cannot rely on index order
SELECT EL.country, EL.region, EL.city, EL.numemps, CL.numcusts
FROM dbo.EmpLocations AS EL
  INNER JOIN dbo.CustLocations AS CL
    ON EL.country = CL.country
    AND ISNULL(EL.region, N'<N/A>') = ISNULL(CL.region, N'<N/A>')
    AND EL.city = CL.city;

-- force MERGE join algorithm, observe sorting in the plan
SELECT EL.country, EL.region, EL.city, EL.numemps, CL.numcusts
FROM dbo.EmpLocations AS EL
  INNER MERGE JOIN dbo.CustLocations AS CL
    ON EL.country = CL.country
    AND ISNULL(EL.region, N'<N/A>') = ISNULL(CL.region, N'<N/A>')
    AND EL.city = CL.city;

-- correct handling of NULLs, can rely on index order
SELECT EL.country, EL.region, EL.city, EL.numemps, CL.numcusts
FROM dbo.EmpLocations AS EL
  INNER JOIN dbo.CustLocations AS CL
    ON EL.country = CL.country
    AND (EL.region = CL.region OR (EL.region IS NULL AND CL.region IS NULL))
    AND EL.city = CL.city;

-- force MERGE join algorithm, observe no sorting in the plan
SELECT EL.country, EL.region, EL.city, EL.numemps, CL.numcusts
FROM dbo.EmpLocations AS EL
  INNER MERGE JOIN dbo.CustLocations AS CL
    ON EL.country = CL.country
    AND (EL.region = CL.region OR (EL.region IS NULL AND CL.region IS NULL))
    AND EL.city = CL.city;

-- alternative combining a join and a set operator while preserving order
SELECT EL.country, EL.region, EL.city, EL.numemps, CL.numcusts
FROM dbo.EmpLocations AS EL
  INNER JOIN dbo.CustLocations AS CL
    ON EXISTS (SELECT EL.country, EL.region, EL.city
               INTERSECT 
               SELECT CL.country, CL.region, CL.city);

SELECT EL.country, EL.region, EL.city, EL.numemps, CL.numcusts
FROM dbo.EmpLocations AS EL
  INNER MERGE JOIN dbo.CustLocations AS CL
    ON EXISTS (SELECT EL.country, EL.region, EL.city
               INTERSECT 
               SELECT CL.country, CL.region, CL.city);

-- cleanup
DROP TABLE IF EXISTS dbo.CustLocations;
DROP TABLE IF EXISTS dbo.EmpLocations;

---------------------------------------------------------------------
-- Multi join queries
---------------------------------------------------------------------

-- attempt to include product category from Production.Categories table
-- inner join nullifies outer part of outer join
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice,
  C.categoryname
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
  INNER JOIN Production.Categories AS C
    ON C.categoryid = P.categoryid
WHERE S.country = N'Japan';

-- fix using outer joins in both joins
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice,
  C.categoryname
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
  LEFT OUTER JOIN Production.Categories AS C
    ON C.categoryid = P.categoryid
WHERE S.country = N'Japan';

-- fix using parentheses
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice,
  C.categoryname
FROM Production.Suppliers AS S
  LEFT OUTER JOIN 
    (Production.Products AS P
       INNER JOIN Production.Categories AS C
         ON C.categoryid = P.categoryid)
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

-- cleanup
DELETE FROM Production.Suppliers WHERE supplierid > 29;
