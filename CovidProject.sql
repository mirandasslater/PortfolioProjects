SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
--shows likelyhood you will die from covid as of April 2021

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Total Cases vs Population

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPositive
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


--Countries with highest infection rate per capita(population)

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Countries with the highest death rate

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Continents with highest death rate

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Why is Canada not included in North America's death count?  The numbers are the same for US and North America...
--This looks more accurate

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS (This gives the total world numbers because it adds all the new cases together)

SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Total not by day, just overall

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2


--Switching to the vaccinations table

SELECT *
FROM CovidVaccinations

--Joining the tables together, on location and date

SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date

-- Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Get a rolling count of vaccines

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations AS int)) 
  OVER (PARTITION BY dea.location
         ORDER BY dea.location,
		 dea.date) AS RollingCountVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Want to see the percentage of the population that is vaccinated, with the rolling count.  
--First going to use a CTE


WITH PopvsVac (Continent, Location, Date, Population, new_vaccination, RollingCountVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations AS int)) 
  OVER (PARTITION BY dea.location
         ORDER BY dea.location,
		 dea.date) AS RollingCountVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (RollingCountVaccinated/Population)*100 AS PercentageofPopVac
FROM PopvsVac


--TEMP TABLE

DROP TABLE if exists #RollingPeopleVaccinated
CREATE TABLE #RollingPeopleVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingCountVaccinated numeric
)

INSERT INTO #RollingPeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations AS int)) 
  OVER (PARTITION BY dea.location
         ORDER BY dea.location,
		 dea.date) AS RollingCountVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingCountVaccinated/Population)*100 AS PercentageofPopVac
FROM #RollingPeopleVaccinated


--CREATE VIEW FOR FUTURE VISUALIZATION

CREATE VIEW PercentPeopleVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations AS int)) 
  OVER (PARTITION BY dea.location
         ORDER BY dea.location,
		 dea.date) AS RollingCountVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3












