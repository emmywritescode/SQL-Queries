--This will concatenate the string values in City and Country and return them in a column called 'City & Country'
--Alternatively the vertical bars '||' must be replaced with a plus sign (+) in SQL server

SELECT FirstName,
LastName,
Address, 
CustomerId,
UPPER(City || ' ' || Country) AS 'City & Country'
FROM Customers;


--This will concatenate a substring of the first 4 letters of the FirstName and the first 2 letters of the LastName and return them in a column called 'new_id'
--The SUBSTRING function must be called in full for SQL server

SELECT FirstName, 
LastName, 
LOWER(SUBSTR(FirstName, 1,4) || SUBSTR(LastName, 1,2)) AS new_id
FROM Employees;


--This will show a list of employees who have worked for the company for 15 or more years using the current date function and ordered by LastName
--DATE('NOW') function must be changed to GETDATE() for SQL server

SELECT FirstName, 
LastName, 
HireDate, 
DATE('NOW'), 
DATE('NOW')-HireDate AS yearsWorked
FROM Employees
WHERE yearsWorked >= 15
ORDER BY LastName ASC;


--This will find the cities with the most customers and rank them in descending order

SELECT City, 
COUNT(City) AS num_of_customers
FROM Customers
GROUP BY City
ORDER BY num_of_customers DESC;


--This nested query will find the names of all the tracks for the album "Californication"

SELECT Name
FROM Tracks
WHERE AlbumId =
(SELECT AlbumId 
fROM Albums
WHERE Title = 'Californication');


--Self joining a table to itself without the join function
--This will retrieve a list with the managers last name, and the last name of the employees who report to him or her

SELECT emp.LastName AS employee,
rept.LastName AS manager
FROM
Employees emp, Employees rept
WHERE emp.EmployeeId = rept.ReportsTo;

--Self joining a table to itself using the inner join function
--This will retrieve a list with the managers last name, and the last name of the employees who report to him or her

SELECT emp.LastName AS employee,
rept.LastName AS manager
FROM
Employees emp
INNER JOIN
Employees rept
ON emp.EmployeeId = rept.ReportsTo;
