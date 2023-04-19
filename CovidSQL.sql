/*
Covid-19 SQL Data Exploration 
Source: https://ourworldindata.org/covid-deaths
Description: Covid data from 01.03.2020 - 18.04.2023
*/


-- Select data which will be the starting point of all quieries

SELECT location, 
		date, 
		total_cases, 
		new_cases, 
		total_deaths, 
		population 
FROM Covid..CovidDeaths
ORDER BY 1,2;


-- Question 1: What is the likelihood of dying from Covid in the Netherlands?
-- DeathPercentage = (total_deaths/total_cases)*100

SELECT Location, 
		date, 
		total_cases,
		total_deaths, 
		(total_deaths/total_cases)*100 AS DeathPercentage
FROM Covid..CovidDeaths
WHERE location LIKE '%netherl%'
AND continent IS NOT NULL
ORDER BY 1,2;


-- Question 2: What is the percentage of population which got Covid in the Netherlands?
-- PercentPopulationInfected = (total_cases/population)*100

SELECT Location, 
		date, Population, 
		total_cases,
		(total_cases/population)*100 as PercentPopulationInfected
FROM Covid..CovidDeaths
WHERE location LIKE '%netherl%'
ORDER BY 1,2;


-- Question 3: What are the top 10 countries with the highest infection rates compared to population?

SELECT TOP (10) Location, 
				Population, MAX(total_cases) as HighestInfectionCount,
				Max((total_cases/population))*100 as PercentPopulationInfected
FROM Covid..CovidDeaths
-- WHERE location LIKE '%nether%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


-- Question 4: What are countries with highest death count per population?

SELECT Location, 
		MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM Covid..CovidDeaths
-- WHERE location LIKE '%nether%'
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- Shwoing breakdown of total death count per population by continent

SELECT continent, 
		MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Shwoing global numbers of total death count per population 

SELECT SUM(new_cases) as total_cases, 
		SUM(cast(new_deaths as int)) as total_deaths, 
		SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Question 5: What is the percentage of population that has recieved at least one Covid vaccine?

SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		ac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated, (RollingPeopleVaccinated/population)*100
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Option 1: Using CTE to perform clculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *,
		(RollingPeopleVaccinated/Population)*100 AS PercentRollingPeopleVaccinated
FROM PopvsVac


-- Option 2: Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
		Continent nvarchar(255),
		Location nvarchar(255),
		Date datetime,
		Population numeric,
		New_vaccinations numeric,
		RollingPeopleVaccinated numeric
)	
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *,
		(RollingPeopleVaccinated/Population)*100 AS PercentRollingPeopleVaccinated
FROM #PercentPopulationVaccinated


-- Creating VIEW to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
