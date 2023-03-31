/*FOR ANALYSIS PURPOSES, DATA WOULD BE OBTAINED FROM DIFFERENT TABLES AND THEN JOINED BASED ON PRIMARY KEYS AND FOREIGN KEYS RELATIONSHIPS*/

USE AdventureWorks2019;

SELECT * FROM Sales.SalesOrderHeader;

SELECT * FROM Sales.SalesOrderDetail;

SELECT * FROM Sales.SalesTerritory;

SELECT * FROM Sales.Customer;

SELECT * FROM Production.ProductCategory;

SELECT * FROM Production.ProductSubcategory;

SELECT * FROM Production.Product;

SELECT * FROM Purchasing.ShipMethod;


/*Returns specific columns from the Sales.SalesOrderHeader table while looking up records in other joined tables for descriptive purposes
A Common Table Expression is used here to create columns from calculated fields*/
WITH SalesOrderTable (SalesOrderID, CustomerID, SalesPersonID, OrderDate, DueDate, ShipDate, ShippingCompany, OrderFulfillmentTime
					,OrderProcessingTime, OrderStatus, OrderType, TerritoryName, OrderContinent)

AS(

SELECT h.SalesOrderID, h.CustomerID, h.SalesPersonID, CAST(h.OrderDate AS DATE) AS 'OrderDate', CAST(h.DueDate AS DATE) AS 'DueDate'
	,CAST(h.ShipDate AS DATE) AS 'ShipDate'	,m.Name AS 'ShippingCompany', DATEDIFF(DAY, OrderDate,DueDate) AS 'OrderFulfillmentTime'
	,DATEDIFF(DAY, OrderDate,ShipDate) AS 'OrderProcessingTime'
	,CASE h.Status
		WHEN 1 THEN 'In Process'
		WHEN 2 THEN 'Approved'
		WHEN 3 THEN 'Backordered'
		WHEN 4 THEN 'Rejected'
		WHEN 5 THEN 'Shipped'
		WHEN 6 THEN 'Cancelled'
		END AS 'OrderStatus'
	,CASE h.OnlineOrderFlag
		WHEN 0 THEN 'Offline'
		WHEN 1 THEN 'Online'
		END AS 'OrderType'
	,t.Name AS 'TerritoryName'
	,t.[Group] AS 'OrderContinent'
FROM Sales.SalesOrderHeader h
	JOIN Sales.SalesTerritory t
	ON h.TerritoryID = t.TerritoryID
	JOIN Purchasing.ShipMethod m
	ON h.ShipMethodID =m.ShipMethodID
)

SELECT *
	,CASE
		WHEN OrderFulfillmentTime >= OrderProcessingTime THEN 'Shipped Early'
		ELSE 'Shipped Late'
		END AS 'ShipmentTiming'
FROM SalesOrderTable;


--Returns specific columns from the Sales.SalesOrderDetail table while looking up records in other joined tables for descriptive purposes
SELECT d.SalesOrderID, d.SalesOrderDetailID, d.ProductID, p.Name AS 'ProductName', c.Name AS 'ProductCategory', s.Name AS 'ProductSubcategory'
		,d.OrderQty, d.UnitPrice, d.UnitPriceDiscount, d.LineTotal AS 'Sales'
FROM Sales.SalesOrderDetail d
	JOIN Production.Product p
	ON d.ProductID = p.ProductID
	JOIN Production.ProductSubcategory s
	ON p.ProductSubcategoryID = s.ProductSubcategoryID
	JOIN Production.ProductCategory c
	ON s.ProductCategoryID = c.ProductCategoryID;


--Returns specified columns from the Sales.Customer table while looking up records in the joined table for descriptive purposes
SELECT c.CustomerID, c.TerritoryID, t.Name AS 'CustomerTerritory'
FROM Sales.Customer c
	JOIN Sales.SalesTerritory t
	ON c.TerritoryID = t.TerritoryID
