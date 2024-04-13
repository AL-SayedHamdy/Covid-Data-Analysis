SELECT *
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL		--Because down there we changed the data type of the total_deaths
ORDER BY 3, 4 DESC


--Exploring the percentage of death over the total cases
--Change the NULL values and make sure it will be float
SELECT location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage --We could cast
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Exploring the percentage of death over the total cases in Egypt
SELECT location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage
FROM CovidAnalysis..CovidDeaths
WHERE location like '%Egypt%'
AND continent IS NOT NULL
ORDER BY 1,2


--Exploring cases and population in the world too see the most infected countries
SELECT location, date, population, total_cases, total_deaths, 
(total_cases / population) * 100 AS InfectionPercentage
FROM CovidAnalysis..CovidDeaths
--WHERE location like '%Egypt%'
WHERE continent IS NOT NULL
ORDER BY 6 DESC


--The most infected countries with the highest cases
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases / population) * 100) AS InfectionPercentage
FROM CovidAnalysis..CovidDeaths
--WHERE location like '%THE COUNTRY THAT YOU WANT%'		--(In case you want to analyse a country)
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionPercentage DESC

--The highest death count countries
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathsCount
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathsCount DESC


--Global death percentage
UPDATE CovidAnalysis..CovidDeaths
SET new_cases = CASE 
    WHEN new_cases = 0 THEN NULL
    ELSE new_cases
END;

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS Total_Deaths,
SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY DeathPercentage DESC



--Let's move to another table
SELECT *
FROM CovidAnalysis..CovidVaccinations
ORDER BY 3, 4

--Total vaccinated people in the world over the population
--Join the date and the location of both tables
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinated
FROM CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--The percentage of the new vaccinated people over the population
--Using temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
TotalVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinated
FROM CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (TotalVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

--Creating views
--First view
CREATE VIEW TotalPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinated
FROM CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM TotalPopulationVaccinated

--Second view
CREATE VIEW DeathPercentage AS
SELECT location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage --We could cast
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL

SELECT *
FROM DeathPercentage


--Third view
CREATE VIEW InfectionPercentage AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases / population) * 100) AS InfectionPercentage
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

SELECT *
FROM InfectionPercentage


--Forth view
CREATE VIEW TotalDeathsCount AS
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathsCount
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

SELECT *
FROM TotalDeathsCount