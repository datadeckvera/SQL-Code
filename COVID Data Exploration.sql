/*
COVID 19 Data Exploration

Skills Used: Wildcards, Aliasing, Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- The COVID dataset used is for a time period of 1st January 2020 to 30th April 2021 for each country.


---- Exploring Infection and Death Rates data in the CovidDeaths table:

--- BREAKING DOWN DATA BY COUNTRY
-- WHERE statement addresses issue with the data where continent data was inputted in the location field instead of the continent field. So rows where continent field is not null show data for countries which is what we want to explore currently.
-- The output  of the query below is ordered by location (third column) and date (fourth column)

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Select the Data that we are starting with:
-- The output of the query below is ordered by iso_code and continent

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--  Total Cases vs Total Deaths:
-- Shows the percentage of people that died out of the total infected for each day

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--  The total_cases and total_deaths fields contain running totals of cases and deaths for the time period of our data. This means the highest values are the total number of cases and the total number of deaths for each country.
-- Using the MAX function to retrieve this data and aggregate the death percentage **for each country**:

SELECT location, population, MAX(total_cases) AS tot_cases, MAX(CAST(total_deaths AS int)) AS tot_deaths, ((MAX(CAST(total_deaths AS int)))/(MAX(total_cases))) * 100 AS CountryDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 1

-- Total Covid Cases vs Deaths Pre and Post Lockdown
-- Using CTE to perform the calculation and return running totals of cases and deaths BY the lockdown date for each country. Remember to run the CTE along with any query which pulls data FROM the CTE table (DeathvLockdown)
-- to return running totals of cases and deaths AFTER the lockdown date, change the <= in the CTE to >

WITH DeathvLockdown (location, population, date, tot_cases, tot_deaths)
AS (
SELECT dea.location, dea.population, dea.date, MAX(total_cases) AS tot_cases, MAX(CAST(total_deaths AS int)) AS tot_deaths
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidLockdowns AS loc
ON dea.location = loc.location
WHERE dea.continent IS NOT NULL AND dea.date <= loc.date
GROUP BY dea.location, dea.population, dea.date
)

SELECT *
FROM DeathvLockdown

-- you can save the output as a View for further queries. For example, on a View named CasesPreLockdown:
-- group by country and show the total cases and deaths (not running totals) for each country by lockdown date 

SELECT location, population, CAST(MAX(date) AS DATE) AS LockdownDate, MAX(tot_cases) AS CasesPreLockdown, MAX(tot_deaths) AS DeathsPreLockdown
FROM CasesPreLockdown
GROUP BY location, population
ORDER BY 1  

-- show what countries initiated lockdowns before any cases or deaths

SELECT location, population, CAST(MAX(date) AS DATE) AS LockdownDate, MAX(tot_cases) AS CasesPreLockdown, MAX(tot_deaths) AS DeathsPreLockdown
FROM CasesPreLockdown
GROUP BY location, population
HAVING MAX(tot_cases) IS NULL AND MAX(tot_deaths) IS NULL
ORDER BY 1

-- To look at DeathPercentage for a particular country, use a wildcard in the WHERE statement. For example to filter for the United **States**:

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Population:
-- Shows **daily** percentage of population infected with  COVID in a country. Query example below is for countries with “states” in their name (United States)

SELECT location, date, total_cases, population, (total_cases/population) * 100 AS PercentPopInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
ORDER BY 1,2

-- To see daily percentage of population infected for **all** countries, comment out the WHERE statement that contains the wildcard:

SELECT location, date, total_cases, population, (total_cases/population) * 100 AS PercentPopInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


--- BREAKING DOWN DATA BY CONTINENT

-- Continents with highest infection count:
-- This returns the total cases for each continent ordered from the highest to lowest case totals

SELECT continent, SUM(new_cases) AS TotalCaseCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalCaseCount DESC

-- Continents with the highest death count per population:
-- This returns the total deaths for each continent ordered from the highest to lowest death counts

SELECT continent, SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--- GLOBAL NUMBERS
-- Shows **daily** percentage of COVID-infected population globally:

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases) AS DeathPercentageGlobal
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- To view the total cases for the entire time period instead of daily, we remove the date field from the select statement and comment out the GROUP BY statement:

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentageGlobal
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


---- Exploring Vaccinations data in the CovidVaccinations table:

-- A look at the CovidVaccinations table shows that the population field is not in this table. So we will need to join this table to the CovidDeaths table for population-related queries:

SELECT *
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date

-- Daily New Vaccinations:
--  Shows the **daily** total of new vaccinations for each country

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Running/Rolling Total of new vaccinations for each country:
-- Output field (rolling_people_vaccinated) contains running totals of vaccinations for the time period of our data. 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Total Population vs Vaccinations:
-- Shows Percentage of Population that has received at least one COVID Vaccine.
-- Use MAX(rolling_people_vaccinated) because that is the total number of people vaccinated in a country for our time period. Divide this by population to know how many people in a country are vaccinated.
-- You will need to use a CTE or Temp Table for this query to address using the output column in the calculation


-- Using CTE to perform the calculation and return percentages of total number of people vaccinated per country (grouped by country):
-- Recall that you must always run the CTE along with any query that you write which pulls data FROM the CTE table (PopvsVac)

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT location, population, MAX(rolling_people_vaccinated) AS total_pop_vaxed, MAX((rolling_people_vaccinated/population) * 100) AS percent_pop_vaxed
FROM PopvsVac
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 1


-- Using Temp Table to perform the calculation and return percentages of total number of people vaccinated per country (grouped by country):
-- Create and populate the Temp Table #PercentPopulationVaccinated, then query the temp table to return the percent_pop_vaxxed output

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT location, population, MAX(rolling_people_vaccinated) AS total_pop_vaxed, MAX((rolling_people_vaccinated/population) * 100) AS percent_pop_vaxed
FROM #PercentPopulationVaccinated
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 1


---- Create Views To Store Data for Later Visualizations:
-- Note that you cannot ORDER BY when creating views and also cannot store temp table output as a view.
-- To store the result of our CTE query as a view 

CREATE VIEW PercentPopVaxxed AS
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT location, population, MAX(rolling_people_vaccinated) AS total_population_vaxed, MAX((rolling_people_vaccinated/population) * 100) AS percent_population_vaxed
FROM PopvsVac
WHERE continent IS NOT NULL
GROUP BY location, population
--ORDER BY 1

-- To query your created view and order by location:

SELECT*
FROM PercentPopVaxxed
ORDER BY 1
