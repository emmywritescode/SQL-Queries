			/*** A DATA CLEANING PROJECT BY EMMANUEL BALOGUN ***/

--Create a new database and ensure the name is not being used by another database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Fifa21')
BEGIN
    CREATE DATABASE Fifa21;
    PRINT 'Database created successfully.';
END
ELSE
BEGIN
    PRINT 'Database already exists.';
END

--Select the database to use
USE Fifa21;

--Retrieve table information
EXEC sp_help 'dbo.fifa21_raw_data_v2';

--Select all columns from the data set for a quick overview
SELECT * FROM dbo.fifa21_raw_data_v2;

--Get the Row Count of the data set
SELECT COUNT(*) AS 'RowCount' FROM dbo.fifa21_raw_data_v2;


/*** THE DATA CLEANING PROCESS ***/


--1. CLEANING THE SPECIAL CHARACTER IN THE 'Name' COLUMN

--Checking to get an overview of the special character 'NCHAR 65533' in the 'Name' column
SELECT * FROM dbo.fifa21_raw_data_v2
WHERE CHARINDEX(NCHAR(65533), Name) = 1

--Replacing all instances of the special character with the first letter of the corresponding 'LongName
SELECT Name,
	CASE
		WHEN CHARINDEX(NCHAR(65533), Name) = 1 THEN REPLACE(Name, NCHAR(65533), SUBSTRING(LongName, 1, 1))
		ELSE Name
	END AS 'NewName'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Name' column
UPDATE dbo.fifa21_raw_data_v2
SET Name = CASE
		WHEN CHARINDEX(NCHAR(65533), Name) = 1 THEN REPLACE(Name, NCHAR(65533), SUBSTRING(LongName, 1, 1))
		ELSE Name
			END
FROM dbo.fifa21_raw_data_v2;



--2. REMOVING THE LEADING WHITE SPACES FROM THE 'Club' COLUMN

--Checking to get an overview of the 'Club' column 
SELECT DISTINCT Club FROM dbo.fifa21_raw_data_v2;

/*** Checking the ASCII character in the 'Club' column.
NOTE: The ASCII character 78 is not a white space but rather represents N from the entry 'No Club' in the column ***/
SELECT DISTINCT ASCII(LEFT(Club, 1)) AS FirstCharacterASCII
FROM dbo.fifa21_raw_data_v2;

--Creating a CTE and a CASE Statement to clean the white space and numeric characters
WITH TrimmedClub AS(
SELECT ID, Club, REPLACE(Club, CHAR(10), '') AS NewClub
FROM dbo.fifa21_raw_data_v2
) 
SELECT ID,
	CASE
		WHEN CHARINDEX('1', NewClub) = 1 AND CHARINDEX('.', NewClub) = 2 AND CHARINDEX(' ', NewClub) = 3 THEN SUBSTRING(NewClub, 4, LEN(NewClub)-3)
		ELSE NewClub
		END AS 'NewClub'
FROM TrimmedClub
ORDER BY Club ASC;

--Selecting the cleaned entries from the CTE to a Temporary Table 'FifaClub'
WITH TrimmedClub AS (
SELECT ID, Club, REPLACE(Club, CHAR(10), '') AS NewClub
FROM dbo.fifa21_raw_data_v2
) 
SELECT ID,
	CASE
		WHEN CHARINDEX('1', NewClub) = 1 AND CHARINDEX('.', NewClub) = 2 AND CHARINDEX(' ', NewClub) = 3
		THEN SUBSTRING(NewClub, 4, LEN(NewClub)-3)
		ELSE NewClub
		END AS 'NewClub'
INTO #FifaClub
FROM TrimmedClub;

--Updating the 'Club' column
UPDATE main
SET Club = NewClub
FROM dbo.fifa21_raw_data_v2 AS main
JOIN #FifaClub AS new
ON main.ID = new.ID;



--3. CLEANING THE 'Contract' COLUMN

--Checking to get an overview of the 'Contract' column 
SELECT DISTINCT Contract FROM dbo.fifa21_raw_data_v2;

--Create New columns 'ContractStart' and 'ContractEnd'
ALTER TABLE dbo.fifa21_raw_data_v2
ADD ContractStart NVARCHAR(50),
	ContractEnd NVARCHAR(50);

--Splitting the Contract column and extracting the year columns from 'Loan End Date' and 'Joined' columns where necessary
SELECT Contract, Joined, [Loan Date End]
	,CASE 
		WHEN Contract LIKE '%~%' THEN RTRIM(PARSENAME(REPLACE(Contract, '~', '.'),2))
		WHEN Contract LIKE '%Loan%' OR Contract = 'Free' THEN LTRIM(PARSENAME(REPLACE(Joined, ',', '.'),1))
		END AS 'Contract Start'
	,CASE
		WHEN Contract LIKE '%~%' THEN LTRIM(PARSENAME(REPLACE(Contract, '~', '.'),1))
		WHEN Contract LIKE '%Loan%' THEN LTRIM(PARSENAME(REPLACE([Loan Date End], ',', '.'),1))
		ELSE Contract END AS 'Contract End'
FROM dbo.fifa21_raw_data_v2

--Updating the 'ContractStart' column
UPDATE dbo.fifa21_raw_data_v2
SET ContractStart = CASE 
		WHEN Contract LIKE '%~%' THEN RTRIM(PARSENAME(REPLACE(Contract, '~', '.'),2))
		WHEN Contract LIKE '%Loan%' OR Contract = 'Free' THEN LTRIM(PARSENAME(REPLACE(Joined, ',', '.'),1))
		END
FROM dbo.fifa21_raw_data_v2;

--Updating the 'ContractEnd' column
UPDATE dbo.fifa21_raw_data_v2
SET ContractEnd = CASE
		WHEN Contract LIKE '%~%' THEN LTRIM(PARSENAME(REPLACE(Contract, '~', '.'),1))
		WHEN Contract LIKE '%Loan%' THEN LTRIM(PARSENAME(REPLACE([Loan Date End], ',', '.'),1))
		ELSE Contract END
FROM dbo.fifa21_raw_data_v2;



--4. CLEANING THE 'Height' COLUMN 

--Checking to get an overview of the 'Height' column 
SELECT DISTINCT Height FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the Height column to centimetres (cm)
SELECT Height,
    CASE
        WHEN Height LIKE '%cm' THEN CAST(SUBSTRING(Height, 1, 3) AS INT)
        WHEN Height LIKE '%"' THEN
            CONVERT(INT, ROUND(CAST(SUBSTRING(Height, 1, CHARINDEX(CHAR(39), Height) - 1) AS INT) * 30.48, 0))
            + CONVERT(INT, ROUND(CAST(SUBSTRING(Height, CHARINDEX(CHAR(39), Height) + 1, CHARINDEX('"', Height) - 3) AS INT) * 2.54, 0))
    END AS 'NewHeight'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Height' column
UPDATE dbo.fifa21_raw_data_v2
SET Height = CASE
        WHEN Height LIKE '%cm' THEN CAST(SUBSTRING(Height, 1, 3) AS INT)
        WHEN Height LIKE '%"' THEN
            CONVERT(INT, ROUND(CAST(SUBSTRING(Height, 1, CHARINDEX(CHAR(39), Height) - 1) AS INT) * 30.48, 0))
            + CONVERT(INT, ROUND(CAST(SUBSTRING(Height, CHARINDEX(CHAR(39), Height) + 1, CHARINDEX('"', Height) - 3) AS INT) * 2.54, 0))
				END
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Height' column to include 'cm' suffix
UPDATE dbo.fifa21_raw_data_v2
SET Height = CONCAT(Height, 'cm');



--5. CLEANING THE 'Weight' COLUMN 

--Checking to get an overview of the 'Weight' column 
SELECT DISTINCT Weight FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the Weight column to kilogram (kg)
SELECT Weight,
    CASE
        WHEN Weight LIKE '%kg' THEN CAST(SUBSTRING(Weight, 1, CHARINDEX('k', Weight)-1) AS INT)
        WHEN Weight LIKE '%lbs' THEN CONVERT(INT, ROUND(CAST(SUBSTRING(Weight, 1, CHARINDEX('l', Weight)-1) AS INT) * 0.454,0))
	END AS 'NewWeight'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Weight' column
UPDATE dbo.fifa21_raw_data_v2
SET Weight = CASE
        WHEN Weight LIKE '%kg' THEN CAST(SUBSTRING(Weight, 1, CHARINDEX('k', Weight)-1) AS INT)
        WHEN Weight LIKE '%lbs' THEN CONVERT(INT, ROUND(CAST(SUBSTRING(Weight, 1, CHARINDEX('l', Weight)-1) AS INT) * 0.454,0))
			END
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Weight' column to include 'kg' suffix
UPDATE dbo.fifa21_raw_data_v2
SET Weight = CONCAT(Weight, 'kg');



--6. CLEANING THE 'Value' COLUMN 

--Checking to get an overview of the 'Value' column 
SELECT DISTINCT Value FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the Value column to their appropriate numeric values
SELECT Value,
    CASE
        WHEN Value LIKE '%M' THEN CAST(SUBSTRING(REPLACE(Value, '€', ''), 1, CHARINDEX('M', Value)-2) AS FLOAT) * 1000000
		WHEN Value LIKE '%K' THEN CAST(SUBSTRING(REPLACE(Value, '€', ''), 1, CHARINDEX('K', Value)-2) AS FLOAT) * 1000
		ELSE 0
	END AS 'NewValue'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Value' column
UPDATE dbo.fifa21_raw_data_v2
SET Value = CASE
        WHEN Value LIKE '%M' THEN CAST(SUBSTRING(REPLACE(Value, '€', ''), 1, CHARINDEX('M', Value)-2) AS FLOAT) * 1000000
		WHEN Value LIKE '%K' THEN CAST(SUBSTRING(REPLACE(Value, '€', ''), 1, CHARINDEX('K', Value)-2) AS FLOAT) * 1000
		ELSE 0
			END
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Value' column to include '€' prefix
UPDATE dbo.fifa21_raw_data_v2
SET Value = CONCAT('€', Value);



--7. CLEANING THE 'Wage' COLUMN 

--Checking to get an overview of the 'Wage' column 
SELECT DISTINCT Wage FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the Wage column to their appropriate numeric values
SELECT Wage,
    CASE
        WHEN Wage LIKE '%K' THEN CAST(SUBSTRING(REPLACE(Wage, '€', ''), 1, CHARINDEX('K', Wage)-2) AS INT) * 1000
		ELSE CAST(SUBSTRING(REPLACE(Wage, '€', ''), 1, LEN(Wage)) AS INT)
	END AS 'NewWage'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Wage' column
UPDATE dbo.fifa21_raw_data_v2
SET Wage = CASE
        WHEN Wage LIKE '%K' THEN CAST(SUBSTRING(REPLACE(Wage, '€', ''), 1, CHARINDEX('K', Wage)-2) AS INT) * 1000
		ELSE CAST(SUBSTRING(REPLACE(Wage, '€', ''), 1, LEN(Wage)) AS INT)
			END
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Wage' column to include '€' prefix
UPDATE dbo.fifa21_raw_data_v2
SET Wage = CONCAT('€', Wage);



--8. CLEANING THE 'Release Clause' COLUMN 

--Checking to get an overview of the 'Release clause' column 
SELECT DISTINCT [Release Clause] FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the 'Release Clause' column to their appropriate numeric values
SELECT [Release Clause],
	CASE
		WHEN [Release Clause] LIKE '%M' THEN CAST(SUBSTRING(REPLACE([Release Clause], '€', ''), 1, CHARINDEX('M', [Release Clause])-2) AS FLOAT) * 1000000
		WHEN [Release Clause] LIKE '%K' THEN CAST(SUBSTRING(REPLACE([Release Clause], '€', ''), 1, CHARINDEX('K', [Release Clause])-2) AS FLOAT) * 1000
		ELSE 0
	END AS 'ReleaseClause'
FROM dbo.fifa21_raw_data_v2;
   
--Updating the 'Release Clause' column
UPDATE dbo.fifa21_raw_data_v2
SET [Release Clause] = CASE
		WHEN [Release Clause] LIKE '%M' THEN CAST(SUBSTRING(REPLACE([Release Clause], '€', ''), 1, CHARINDEX('M', [Release Clause])-2) AS FLOAT) * 1000000
		WHEN [Release Clause] LIKE '%K' THEN CAST(SUBSTRING(REPLACE([Release Clause], '€', ''), 1, CHARINDEX('K', [Release Clause])-2) AS FLOAT) * 1000
		ELSE 0
			END
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Release Clause' column to include '€' prefix
UPDATE dbo.fifa21_raw_data_v2
SET [Release Clause] = CONCAT('€', [Release Clause]);



--9. CLEANING THE 'WF' COLUMN 

--Checking to get an overview of the 'WF' column 
SELECT DISTINCT WF FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the 'WF' column to their appropriate numeric values
SELECT WF, SUBSTRING(WF, 1, 1) AS 'NewWF'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'WF' column
UPDATE dbo.fifa21_raw_data_v2
SET WF = SUBSTRING(WF, 1, 1)
FROM dbo.fifa21_raw_data_v2;



--10. CLEANING THE 'SM' COLUMN 

--Checking to get an overview of the 'SM' column 
SELECT DISTINCT SM FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the 'SM' column to their appropriate numeric values
SELECT SM, SUBSTRING(SM, 1, 1) AS 'NewSM'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'SM' column
UPDATE dbo.fifa21_raw_data_v2
SET SM = SUBSTRING(SM, 1, 1)
FROM dbo.fifa21_raw_data_v2;



--11. CLEANING THE 'IR' COLUMN 

--Checking to get an overview of the 'IR' column 
SELECT DISTINCT IR FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the 'IR' column to their appropriate numeric values
SELECT IR, SUBSTRING(IR, 1, 1) AS 'NewIR'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'IR' column
UPDATE dbo.fifa21_raw_data_v2
SET IR = SUBSTRING(IR, 1, 1)
FROM dbo.fifa21_raw_data_v2;



--12. CLEANING THE 'Hits' COLUMN 

--Checking to get an overview of the 'Hits' column 
SELECT DISTINCT Hits FROM dbo.fifa21_raw_data_v2;

--Converting all entries in the 'Hits' column ending with 'K' to their appropriate numeric values
SELECT Hits,
	CASE
		WHEN Hits LIKE '%K' THEN CONVERT(NVARCHAR(20), CAST(SUBSTRING(Hits, 1, LEN(Hits)-1) AS FLOAT) * 1000)
		WHEN Hits LIKE '%[0-9]%' THEN CONVERT(NVARCHAR(20), Hits)
		ELSE '-'
	END AS 'NewHits'
FROM dbo.fifa21_raw_data_v2;

--Updating the 'Hits' column
UPDATE dbo.fifa21_raw_data_v2
SET Hits = CASE
		WHEN Hits LIKE '%K' THEN CONVERT(NVARCHAR(20), CAST(SUBSTRING(Hits, 1, LEN(Hits)-1) AS FLOAT) * 1000)
		WHEN Hits LIKE '%[0-9]%' THEN CONVERT(NVARCHAR(20), Hits)
		ELSE '-'
			END
FROM dbo.fifa21_raw_data_v2;



--13.  REMOVING DUPLICATES VALUES

--Creating a CTE to perform a row count
WITH DuplicateCheck AS (
SELECT*, ROW_NUMBER() OVER(PARTITION BY Name, LongName, Nationality, Club, Age, Height ORDER BY ID) AS RowNumber
FROM dbo.fifa21_raw_data_v2
)
SELECT * FROM DuplicateCheck
WHERE RowNumber > 1;

/*** Checking further to ensure the returned value from the duplicate check is really a duplicate. 
NOTE: It was observed that no duplicate existed. ***/
SELECT * FROM dbo.fifa21_raw_data_v2
WHERE LongName = 'Peng Wang'



--14.  DROPPING IRRELEVANT COLUMNS

--Dropping Irrelevant columns
ALTER TABLE dbo.fifa21_raw_data_v2
DROP COLUMN photoUrl;