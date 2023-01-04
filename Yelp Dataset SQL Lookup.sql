--This profiles the 'business' table and returns the total number of records in the table

SELECT COUNT(*)
FROM
business;


--This counts the distinct values in the 'category' table using the specified foreign key called 'business_id'. 

SELECT COUNT(DISTINCT business_id)
FROM
category;


--This will check for null values in the listed columns of the 'user' table. If a table contains a primary key column, there is no need to check that column since the column cannot accept null values.

SELECT *
FROM
user
WHERE 
name IS NULL OR
review_count IS NULL OR
useful IS NULL OR
funny IS NULL OR
cool IS NULL OR
fans IS NULL OR
average_stars IS NULL OR
compliment_hot IS NULL OR
compliment_more IS NULL OR
compliment_profile IS NULL OR
compliment_cute IS NULL OR
compliment_list IS NULL OR
compliment_note IS NULL OR
compliment_plain IS NULL OR
compliment_cool IS NULL OR
compliment_funny IS NULL OR
compliment_writer IS NULL OR
compliment_photos IS NULL;


--This will check for maximum, minimum and average of the number values in the specified column 'stars' in the 'review' table

SELECT MAX(stars),
MIN(stars),
AVG(stars)
FROM
review;


--This will list the cities with the most reviews in descending order in a column called 'NumberOfReviews'

SELECT city, 
SUM(review_count) AS NumberOfReviews
FROM
business
GROUP BY city
ORDER BY NumberOfReviews DESC;


--This will list the distribution of star ratings in the city of 'Avon' in a column called 'Occurrence in Avon'

SELECT stars,
COUNT(stars) AS 'Occurrence in Avon'
FROM
business
WHERE city = 'Avon'
GROUP BY stars;


--This will find the top 3 users based on their total number of reviews

SELECT name,
review_count AS NumberOfReviews
FROM
user
ORDER BY NumberOfReviews DESC
LIMIT 3;


--This will use a CASE statement to check if there are more reviews with the word "love" or with the word "hate" in them from the 'text' column in the 'review' table

SELECT
COUNT(CASE WHEN text LIKE '%love%' THEN 1 END) AS LoveCount,
COUNT(CASE WHEN text LIKE '%hate%' THEN 0 END) AS HateCount
FROM
review;


/*This will group the specified business category 'Restaurants' in the specified city 'Toronto' and categorizes them by ratings of '2 & 3' and '4 & 5' using a CASE statement. In addition, it creates an additional column called 'Customer Rating' and will also return all the corresponding
columns in the tables joined. However, the hours column is the only column that will be returned from the 'hours' table */

SELECT b.*,
c.*,
h.hours,
CASE
     WHEN stars BETWEEN 2 AND 3 THEN 'Fair'
     WHEN stars BETWEEN 4 AND 5 THEN 'Very Good'
     ELSE 'Undefined'
END AS 'Customer Rating'
FROM
business b
INNER JOIN
category c
ON b.id = c.business_id
INNER JOIN
hours h
ON b.id = h.business_id
WHERE b.city = 'Toronto' AND c.category = 'Restaurants';