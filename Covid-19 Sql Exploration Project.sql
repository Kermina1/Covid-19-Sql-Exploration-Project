/*
Covid 19 Data Exploration (2020-2021).

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT * 
FROM sql_exploration_project..CovidDeaths
ORDER BY 3,4;

-- Select the data that we are going to start with.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total cases VS Total deaths
-- This shows the likelihood of death with covid-19.
/*By calculating the death percentage, we can understand 
the fatality rate of COVID-19 in different locations over time.*/
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) as DeathPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, date, total_cases, total_deaths
ORDER BY location, date;

-- Death Rate in Egypt.
SELECT location, date,population,total_cases, total_deaths,ROUND((total_deaths/total_cases)*100,2) as EgyptDeathPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL and location = 'Egypt'
GROUP BY location, date, total_cases, total_deaths, population
ORDER BY location, date;

-- Looking at total cases vs population.
-- What percentage of population got covid.
SELECT location, date, population ,total_cases,ROUND((total_cases/population)*100,2) as InfectedPopulationPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location, date, total_cases, total_deaths, population
ORDER BY location, date;

--Infection Rate in Egypt.
SELECT location, date, population ,total_cases,ROUND((total_cases/population)*100,2) as InfectedPopulationPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL AND location = 'Egypt'
GROUP BY location, date, total_cases, total_deaths, population
ORDER BY location, date;

-- Looking at highest country's infections rate with covid-19
SELECT location,population ,max(total_cases) as HighestInfections,MAX(ROUND((total_cases/population)*100,2)) as HighestInfectedPopulationPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location,population
ORDER BY HighestInfectedPopulationPercentage DESC;
	
-- Egypt highest infection rate.
SELECT location,population ,max(total_cases) as HighestInfections,MAX(ROUND((total_cases/population)*100,2)) as HighestInfectedPopulationPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL AND location = 'Egypt'
GROUP BY location,population
ORDER BY HighestInfectedPopulationPercentage DESC;

-- This query to get the exact date with the highest infection in Egypt.
WITH MaxCases AS (
    SELECT location, population, MAX(total_cases) AS HighestInfections
    FROM sql_exploration_project..CovidDeaths
    WHERE continent IS NOT NULL AND location = 'Egypt'
    GROUP BY location, population
)
SELECT d.location, d.population, d.date, d.total_cases AS HighestInfections,
       ROUND((d.total_cases/d.population)*100, 2) AS HighestInfectedPopulationPercentage
FROM sql_exploration_project..CovidDeaths AS d
JOIN MaxCases AS m
	ON d.location = m.location AND d.population = m.population AND d.total_cases = m.HighestInfections
WHERE d.continent IS NOT NULL AND d.location = 'Egypt'
ORDER BY d.date;

-- Countries with highest death count per population.
SELECT location,population ,max(cast(total_deaths as INT))as HighestDeathsCount
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY HighestDeathsCount DESC;

-- Countries with highest death count in Egypt.
SELECT date,location,population ,max(cast(total_deaths as INT))as HighestDeathsCount
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL AND location = 'Egypt'
GROUP BY date,location,population
ORDER BY HighestDeathsCount DESC;

-- Breaking things by continent.
-- Continent with the highest death count.
SELECT continent, MAX(cast(Total_deaths as int)) as DeathCount
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER By DeathCount DESC;

-- Showing Golobal Numbers for everyday
SELECT date,sum(new_cases) as total_cases, sum(Cast(new_deaths as int)) as total_death,ROUND(SUM(cast(new_deaths as int))/SUM(New_Cases)*100,2) as DeathPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
Order By total_death;

-- Showing total Golobal Numbers 
SELECT sum(new_cases) as total_cases, sum(Cast(new_deaths as int)) as total_death,ROUND(SUM(cast(new_deaths as int))/SUM(New_Cases)*100,2) as DeathPercentage
FROM sql_exploration_project..CovidDeaths
WHERE continent IS NOT NULL
Order By total_death;

-- Total population vs vaccination.
-- Join the two tables.
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS INT)) OVER(partition by d.location order by d.location, d.date) AS CummulativeVaccineTotal
FROM sql_exploration_project..CovidVaccinations AS v
JOIN sql_exploration_project..CovidDeaths AS d
	ON v.location = d.location AND v.date = d.date
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date;

-- Use CTE to be able to use the window function in the previous query.
-- Calculate the cummulative vaccination percentage aganist population 
WITH vacpop as (
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS INT)) OVER(partition by d.location order by d.location, d.date) AS CummulativeVaccineTotal
FROM sql_exploration_project..CovidVaccinations AS v
JOIN sql_exploration_project..CovidDeaths AS d
	ON v.location = d.location AND v.date = d.date
WHERE d.continent IS NOT NULL
)
SELECT *, (CummulativeVaccineTotal/Population)*100 as VaccinePercentage
FROM vacpop;

-- Use Temp table as an another way use CummulativeVaccineTotal the window function.
DROP TABLE IF exists #VaccineVSPop --TO alter table if needed.
CREATE TABLE #VaccineVSPop (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CummulativeVaccineTotal numeric
)
--Insert into table.
INSERT INTO #VaccineVSPop
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS INT)) OVER(partition by d.location order by d.location, d.date) AS CummulativeVaccineTotal
FROM sql_exploration_project..CovidVaccinations AS v
JOIN sql_exploration_project..CovidDeaths AS d
	ON v.location = d.location AND v.date = d.date
WHERE d.continent IS NOT NULL;

SELECT *,(CummulativeVaccineTotal/Population)*100 vaccinePercentage
FROM #VaccineVSPop;


--CREATE a view for later visualisation usage.
DROP VIEW IF exists VaccineVsPopulation

CREATE VIEW VaccineVsPopulation AS 
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS INT)) OVER(partition by d.location order by d.location, d.date) AS CummulativeVaccineTotal
FROM sql_exploration_project..CovidVaccinations AS v
JOIN sql_exploration_project..CovidDeaths AS d
	ON v.location = d.location AND v.date = d.date
WHERE d.continent IS NOT NULL

SELECT * FROM sys.views -- To ensure the view is created.

