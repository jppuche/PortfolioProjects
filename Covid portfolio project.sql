--1- Downloaded data on Coronavirus (COVID-19) deaths and vaccinations from Our World in Data (https://ourworldindata.org/covid-deaths). The data is from the 08/01/2020 - 12/06/2023 period (316,712 rows in total).
--2- Transformed the downloaded .csv file into a .xlsx file using Microsoft Excel.
--3- Separated the data into two different tables: one for death data and one for vaccination data.
--4- Import both tables into SQL Server. 
--5- Verified each column is set to the correct data type. (nvarchar, numeric, date...)
--6- Start of queries:


-- Verify the tables were imported correctly:

SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY location, date

SELECT * 
FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4


-- A quick look of the data that I'll be using the most in the following queries:

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2, 3


-- Looking at total cases vs total deaths in all countries:
-- (shows percentage of fatal cases among infected people, by date)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent != ''  --(used to exclude non-countries locations)
ORDER BY 1, 2


-- Looking at total cases vs total deaths in Argentina 
-- (shows percentage of fatal cases among infected people, by date).

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Argentina'
ORDER BY 1, 2


-- Looking at total cases vs population in Argentina 
-- (shows percentage of population that got infected, by date)

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Argentina'
ORDER BY 1, 2


-- Looking at countries with highest infection rate compared to population:
-- (shows a list of all countries and the percentage of its population that got infected, from most to least)

SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Percent_Population_Infected
FROM PortfolioProject..CovidDeaths
WHERE continent != ''  
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC


-- Looking at countries with highest death count per population:
-- (shows a list of all countries and the percentage of the population that passed away, from most to least)

SELECT location, population, MAX(total_deaths) AS Highest_Death_Count, MAX((total_deaths/population))*100 AS Percent_Population_Dead
FROM PortfolioProject..CovidDeaths
WHERE continent != ''                      
GROUP BY location, population
ORDER BY Percent_Population_Dead DESC


-- Let's break things down by continent:
-- (shows a list of continents, plus European Union and World, and the percentage of the population that passed away, from most to least)

SELECT location, MAX(total_deaths) AS Highest_Death_Count, MAX((total_deaths/population))*100 AS Percent_Population_Dead
FROM PortfolioProject..CovidDeaths
WHERE continent = '' AND location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY continent, location
ORDER BY Percent_Population_Dead DESC


-- GLOBAL NUMBERS:
-- (Total cases vs total deaths)

SELECT SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent != '' AND new_cases != 0 


-- Looking at total population vs vaccinations:
-- (shows the sum of people vaccinated, by date)

	-- Method 1, using a CTE:

WITH PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePeopleVaccinated
FROM PopvsVac
ORDER BY 2, 3


	-- Method 2, using a temp table:

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePeopleVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2, 3


-- Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''