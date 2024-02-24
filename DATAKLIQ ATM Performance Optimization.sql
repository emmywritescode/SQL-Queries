/* -----------------DATAKLIQ ATM Performance Optimization---------------- */

--UNDERSTANDING THE DATA SETS
SELECT * FROM dbo.[atm_location lookup];

SELECT * FROM dbo.ATM_Maintenance_Schedule_Lookup;

SELECT * FROM dbo.customers_lookup_Info;

SELECT * FROM dbo.[hour lookup];

SELECT * FROM dbo.[transaction_type lookup];

SELECT TOP (1000) [TransactionID]
      ,[TransactionStartDateTime]
      ,[TransactionEndDateTime]
      ,[CardholderID]
      ,[LocationID]
      ,[TransactionTypeID]
      ,[TransactionAmount]
      ,[ATM_ID]
  FROM [atm].[dbo].[Enugu State];


SELECT TOP (1000) [TransactionID]
      ,[TransactionStartDateTime]
      ,[TransactionEndDateTime]
      ,[CardholderID]
      ,[LocationID]
      ,[TransactionTypeID]
      ,[TransactionAmount]
      ,[ATMID]
  FROM [atm].[dbo].[Lagos State];


--1. Merge all the state transactions by creating a table
CREATE TABLE transactions
(
[TransactionID] NVARCHAR(50)
      ,[TransactionStartDateTime] NVARCHAR(50)
      ,[TransactionEndDateTime] NVARCHAR(50)
      ,[CardholderID] NVARCHAR(50)
      ,[LocationID] NVARCHAR(50)
      ,[TransactionTypeID] NVARCHAR(50)
      ,[TransactionAmount] NVARCHAR(50)
      ,[ATM_ID] NVARCHAR(50)
);

INSERT INTO transactions

	SELECT * FROM dbo.[Enugu State]
	UNION
	SELECT * FROM dbo.[Fct s]
	UNION
	SELECT * FROM dbo.[Kano State]
	UNION
	SELECT * FROM dbo.[Lagos State]
	UNION
	SELECT * FROM dbo.[Rivers State n];


--View all transactions // 6,523,792 rows
SELECT * FROM transactions;


--2. Add TransactionDuration(Minutes & Hours) & TransactionHour to Transactions table
ALTER TABLE transactions
ADD [TransactionDuration (Minutes)] INT,
     [TransactionDuration (Hours)] FLOAT,
	 [TransactionHour] TINYINT;

UPDATE transactions
SET [TransactionDuration (Minutes)]  =  DATEDIFF(MINUTE,CAST(TransactionStartDateTime AS DATETIME), CAST(TransactionEndDateTime AS DATETIME))

UPDATE transactions
SET [TransactionDuration (Hours)] = ROUND([TransactionDuration (Minutes)] * 1.00/60, 2)

UPDATE transactions
SET [TransactionHour] = DATEPART(HOUR, CAST(TransactionStartDateTime AS TIME))

--View all transactions // 6,523,792 rows
SELECT * FROM transactions;


--3. Create a Calendar lookup table for the transactions from 2019 to 2022
CREATE TABLE calendar_lookup
(
	[Date] DATE
    ,[Year] SMALLINT
    ,[Month Name] VARCHAR(20)
    ,[Month] SMALLINT
    ,[Quarter] VARCHAR(20)
    ,[Week of Year] SMALLINT
    ,[Day of Week] VARCHAR(20)
    ,[Day Name] VARCHAR(20)
	,[Is Holiday] TINYINT
);

--Input date values
DECLARE @StartDate DATE = '01/01/2019';
DECLARE @EndDate DATE = '12/31/2023';

WHILE @StartDate <= @EndDate
BEGIN
	INSERT INTO calendar_lookup ([Date]) VALUES (@StartDate);
	SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;

--Input year values
UPDATE calendar_lookup
SET [Year] = YEAR([Date]); 

--Input month values
UPDATE calendar_lookup
SET [Month] = MONTH([Date]); 

--Input month name
UPDATE calendar_lookup
SET [Month Name] = DATENAME(MONTH, [Date]);

--Input day name
UPDATE calendar_lookup
SET [Day Name] = FORMAT([Date], 'dddd');

--Input day of week
UPDATE calendar_lookup
SET [Day of Week] = DATEPART(DW, [Date]);

--Input week of year
UPDATE calendar_lookup
SET [Week of Year] = DATEPART(WEEK, [Date]); 

--Input Quarter
UPDATE calendar_lookup
SET [Quarter] = 
	CASE WHEN [Month] IN (1,2,3) THEN 'Q1'
		WHEN [Month] IN (4,5,6) THEN 'Q2'
		WHEN [Month] IN (7,8,9) THEN 'Q3'
		ELSE 'Q4' END;

--Input Holiday
UPDATE calendar_lookup
SET [Is Holiday] = 
		CASE WHEN Date LIKE '%01-01' OR
				  Date LIKE '%01-03' OR
				  Date LIKE '%05-04' OR
				  Date LIKE '%05-30' OR
				  Date LIKE '%07-10' OR
				  Date LIKE '%10-03' OR
				  Date LIKE '%12-25' OR
				  Date LIKE '%12-26'
				THEN 1 ELSE 0 END;

--View calendar_lookup table
SELECT * FROM calendar_lookup


--4. Update the ATM_Maintenance_Schedule_Lookup table
SELECT * FROM ATM_Maintenance_Schedule_Lookup

--Update column MTBF (hours), replace N/A with Mean
UPDATE ATM_Maintenance_Schedule_Lookup
SET [MTBF (hours)] = (SELECT AVG(CAST([MTBF (hours)] AS INT))
						FROM ATM_Maintenance_Schedule_Lookup
						WHERE [MTBF (hours)] <> 'N/A')
WHERE [MTBF (hours)] = 'N/A';

--Update column MTTR (hours), replace N/A with Mean
UPDATE ATM_Maintenance_Schedule_Lookup
SET [MTTR (hours)] = (SELECT AVG(CAST([MTTR (hours)] AS INT))
						FROM ATM_Maintenance_Schedule_Lookup
						WHERE [MTTR (hours)] <> 'N/A')
WHERE [MTTR (hours)] = 'N/A';

--Update column Cash Availability, replace N/A with Mode
 WITH Ranked AS
		(
		SELECT [Cash Availability], COUNT(*) AS 'count', DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS 'rank'
		FROM ATM_Maintenance_Schedule_Lookup
		WHERE [Cash Availability] <> 'N/A'
		GROUP BY [Cash Availability]
		)
UPDATE ATM_Maintenance_Schedule_Lookup	
SET [Cash Availability] = (SELECT [Cash Availability] FROM Ranked
						  WHERE rank = 1)
WHERE [Cash Availability] = 'N/A';

--Update column Cash Replenishment Cycle, replace N/A with Mode
 WITH Ranked AS
		(
		SELECT [Cash Replenishment Cycle], COUNT(*) AS 'count', DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS 'rank'
		FROM ATM_Maintenance_Schedule_Lookup
		WHERE [Cash Replenishment Cycle] <> 'N/A'
		GROUP BY [Cash Replenishment Cycle]
		)
UPDATE ATM_Maintenance_Schedule_Lookup	
SET [Cash Replenishment Cycle] = (SELECT [Cash Replenishment Cycle] FROM Ranked
						         WHERE rank = 1)
WHERE [Cash Replenishment Cycle] = 'N/A';

--Update column Transaction Success Rate (Percent), replace N/A with Mean
UPDATE ATM_Maintenance_Schedule_Lookup
SET [Transaction Success Rate (Percent)] = (SELECT ROUND(AVG(CAST([Transaction Success Rate (Percent)] AS DECIMAL)),1)
						FROM ATM_Maintenance_Schedule_Lookup
						WHERE [Transaction Success Rate (Percent)] <> 'N/A')
WHERE [Transaction Success Rate (Percent)] = 'N/A';

--Update column Error Rate (%), replace N/A with Mean
UPDATE ATM_Maintenance_Schedule_Lookup
SET [Error Rate (%)] = (SELECT ROUND(AVG(CAST([Error Rate (%)] AS DECIMAL)),1)
						FROM ATM_Maintenance_Schedule_Lookup
						WHERE [Error Rate (%)] <> 'N/A')
WHERE [Error Rate (%)] = 'N/A';

--Update column Service Response Time (minutes), replace N/A with Mean
UPDATE ATM_Maintenance_Schedule_Lookup
SET [Service Response Time (minutes)] = (SELECT AVG(CAST([Service Response Time (minutes)] AS INT))
						FROM ATM_Maintenance_Schedule_Lookup
						WHERE [Service Response Time (minutes)] <> 'N/A')
WHERE [Service Response Time (minutes)] = 'N/A';

--Update column ATM Utilization, replace N/A with Mean
UPDATE ATM_Maintenance_Schedule_Lookup
SET [ATM Utilization] = (SELECT AVG(CAST([ATM Utilization] AS INT))
						FROM ATM_Maintenance_Schedule_Lookup
						WHERE [ATM Utilization] <> 'N/A')
WHERE [ATM Utilization] = 'N/A';

--update column ATM Dwell Time (seconds)
UPDATE ATM_Maintenance_Schedule_Lookup
SET [ATM Dwell Time (seconds)] = (SELECT AVG(CAST([ATM Dwell Time (seconds)] AS INT))
						FROM ATM_Maintenance_Schedule_Lookup
						WHERE [ATM Dwell Time (seconds)] <> 'N/A')
WHERE [ATM Dwell Time (seconds)] = 'N/A';