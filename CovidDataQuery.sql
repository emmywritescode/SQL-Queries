SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;

SELECT * 
FROM PortfolioProject..CovidVaccinations
ORDER BY location, date;

--Query sample to obtain data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
--WHERE location IN ('Nigeria' , 'United States')
ORDER BY location, date;

--Percentage of Total deaths to Total cases
--Shows the probability of dying from Covid in Nigeria and the United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS "percentage_death_to_cases"
FROM PortfolioProject..CovidDeaths
--WHERE location IN ('Nigeria', 'United States')
ORDER BY location, date;

--Percentage of Total cases to Population
--Shows the percentage of the Population with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS "percentage_cases_to_population"
FROM PortfolioProject..CovidDeaths
--WHERE location IN ('Nigeria', 'United States')
ORDER BY location, date;

--To get the Countries with the highest infection rate

SELECT location, population, MAX(total_cases) AS "highest_infection_count", MAX(total_cases/population)*100 AS "highest_percentage_cases_to_population"
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY highest_percentage_cases_to_population DESC;

--To get the Countries with the highest death rate

SELECT location, population, MAX(CAST(total_deaths AS INT)) AS "highest_death_count", MAX(CAST(total_deaths AS INT)/population)*100 AS "highest_percentage_deaths_to_population"
FROM PortfolioProject..CovidDeaths
--WHERE location like '%state%'
GROUP BY location, population
ORDER BY highest_percentage_deaths_to_population DESC;

/*In the Original data, it is observed that the value of continent is set to NULL when location carries 
a value for a continent's name (e.g location = Africa) instead of the usual country name (e.g location = Nigeria).
HENCE, to retrieve data representative of countries only, "WHERE continent IS NOT NULL" is used*/

--Shows the maximum total deaths obtained from individual countries alone.

SELECT location, population, MAX(CAST(total_deaths AS INT)) AS "highest_death_count", MAX(CAST(total_deaths AS INT)/population)*100 AS "highest_percentage_deaths_to_population"
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_percentage_deaths_to_population DESC;

--Shows the maximum total deaths by the continents and other location groups (excludes all locations WHERE continent is NOT NULL)

SELECT location, MAX(CAST(total_deaths AS INT)) AS "highest_death_count"
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_death_count DESC;

--Shows maximum of total deaths by the continents

SELECT continent, MAX(CAST(total_deaths AS INT)) AS "highest_death_count"
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count DESC;

--Global New COVID cases and deaths for each day

SELECT date, SUM(new_cases) AS 'global_cases', SUM(CAST(new_deaths AS INT)) AS 'global_deaths', SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS 'percentage_global_deaths'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

--Join Deaths and Vaccinations table

SELECT *
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND
d.date = v.date;

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date;


-- Total Vaccinations against population

SELECT location, population, MAX(CAST(total_vaccinations AS BIGINT)) AS 'highest_total_vaccinations'
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY location;


--Using a Common Table Expression (CTE)

WITH covid_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)

AS (

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS "rolling_people_vaccinated" --,(rolling_people_vaccinated/population) * 100
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location, d.date;
)

SELECT *,(rolling_people_vaccinated/population) * 100 AS "percentage_population_vaccinated"
FROM covid_vac;


--Creating a Temporary Table

USE PortfolioProject;

DROP TABLE IF EXISTS #population_vaccination;

CREATE TABLE #population_vaccination(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population BIGINT,
new_vaccinations BIGINT,
rolling_people_vaccinated BIGINT
)

INSERT INTO #population_vaccination

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS "rolling_people_vaccinated" --,(rolling_people_vaccinated/population) * 100
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location, d.date;

SELECT *,(rolling_people_vaccinated/population) * 100 AS "percentage_population_vaccinated"
FROM #population_vaccination;

--Creating Views for Visualizations

CREATE VIEW population_vaccination AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS "rolling_people_vaccinated" --,(rolling_people_vaccinated/population) * 100
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location AND
d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY d.location, d.date;

CREATE VIEW global_vaccination AS
SELECT date, SUM(new_cases) AS 'global_cases', SUM(CAST(new_deaths AS INT)) AS 'global_deaths', SUM(CAST(new_deaths AS INT))/SUM(new_cases) AS 'percentage_global_deaths'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
--ORDER BY date;
