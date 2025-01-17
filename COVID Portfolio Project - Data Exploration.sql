/*
Covid 19 Data Exploration 
By Asheen Thomas

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 3,4

-- Select Data that we are going to be using
SELECT location,date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2

-- Looking at the Total Cases vs Total Deaths
-- Shows the liklihood of dying if you contract Covid in the US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at the Population vs Total Cases
-- Shows what percentage of population got Covid in the US
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_infected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Showing countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX(total_cases/population)*100 AS percent_infected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
Group by location, population
ORDER BY percent_infected desc

-- Showing the countries with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
Group by location
ORDER BY total_death_count desc


---BROKEN DOWN BY CONTINENT
-- Showing the countries with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
Group by continent
ORDER BY total_death_count desc

-- GLOBAL NUMBERS (cases, deaths, and death percentage)
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100   AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


Select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as rolling_people_vaccinated
From PortfolioProject..CovidDeaths deaths
Join PortfolioProject..CovidVaccinations vac
	On deaths.location = vac.location
	and deaths.date = vac.date
where deaths.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vac
	On deaths.location = vac.location
	and deaths.date = vac.date
WHERE deaths.continent is not null 
)
SELECT *, (rolling_people_vaccinated/Population)*100  AS rolling_percent_vacinated
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent is NOT NULL 

SELECT *, (rolling_people_vaccinated/Population)*100  AS rolling_percent_vacinated
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccinations vac
	ON deaths.location = vac.location
	AND deaths.date = vac.date
where deaths.continent is NOT NULL 

SELECT * 
FROM PercentPopulationVaccinated