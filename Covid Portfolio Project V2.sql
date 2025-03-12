SELECT *
FROM PortfolioCovidDataset..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioCovidDataset..CovidVaccinations
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioCovidDataset..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Total cases VS Total deaths
-- & likelyhood of deaths in Canada

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100.0 AS DeathPercentage
FROM PortfolioCovidDataset..CovidDeaths
WHERE location like '%canada%' AND continent is not null
ORDER BY 1,2

-- Looking at Total_cases VS Population that got Covid

SELECT location, date, population, total_cases, (total_cases/population)* 100.0 AS PercentagePopulationInfected
FROM PortfolioCovidDataset..CovidDeaths
WHERE continent is not null
--WHERE location like '%canada%'
ORDER BY 1,2

--Highest infection rate country compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount,
MAX((total_cases/population))* 100.0 AS PercentPopulationInfected
FROM PortfolioCovidDataset..CovidDeaths
WHERE continent is not null
--WHERE location like '%canada%'
GROUP BY population, location
ORDER BY PercentPopulationInfected desc

--Countries with the highest death per population

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathsCount
FROM PortfolioCovidDataset..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathsCount desc

-- Now Analyze by continent with the highest death rate

SELECT continent, MAX(CAST(total_deaths as int)) as ContinentDeathsCount
FROM PortfolioCovidDataset..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY ContinentDeathsCount desc

-- Because in the dataset the continents cases are being written into location separately or as an aggregation

SELECT location, MAX(CAST(total_deaths as int)) as Continent2DeathsCount
FROM PortfolioCovidDataset..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY Continent2DeathsCount desc



--Global counts

SELECT date, SUM(total_cases) as TotalCase, SUM(new_cases) as TotalNewCase, SUM(CAST(new_deaths as int)) as TotalNewDeaths,
	SUM(CAST(new_deaths as int))*100.0/SUM(new_cases) as NewDeathPercentage
FROM PortfolioCovidDataset..CovidDeaths
Where continent is not null
GROUP BY date
ORDER BY 1,2

----- Just the total counts

SELECT FORMAT(SUM(total_cases), 'N0') as TotalCase, FORMAT(SUM(new_cases), 'N0') as TotalNewCase,
	FORMAT(SUM(CAST(new_deaths as int)), 'N0') as TotalNewDeaths,
	FORMAT(SUM(CAST(new_deaths as int))*100.0/SUM(new_cases), 'N2') as NewDeathPercentage
FROM PortfolioCovidDataset..CovidDeaths
Where continent is not null
--GROUP BY date
ORDER BY 1,2


-- Total population vs vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location ,dea.date) as rolling_ppl_vacc
FROM PortfolioCovidDataset..CovidDeaths dea
JOIN PortfolioCovidDataset..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3



--- CTE


WITH Pop_vs_vacc (Continent, Location, Date, Population, new_vaccinations, rolling_ppl_vacc) AS (

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location ,dea.date) as rolling_ppl_vacc
FROM PortfolioCovidDataset..CovidDeaths dea
JOIN PortfolioCovidDataset..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (rolling_ppl_vacc/Population)*100.0 as 
FROM Pop_vs_vacc




--Temp table
DROP Table if exists #PercentPopulationVaccinated
GO
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric,
rolling_ppl_vacc numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location ,dea.date) as rolling_ppl_vacc
FROM PortfolioCovidDataset..CovidDeaths dea
JOIN PortfolioCovidDataset..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3


SELECT *, (rolling_ppl_vacc/Population)*100.0 
FROM #PercentPopulationVaccinated




--Creating view for later visualizations
DROP View if exists dbo.PercentPopulationVaccinated
GO
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location ,dea.date) as rolling_ppl_vacc
FROM PortfolioCovidDataset..CovidDeaths dea
JOIN PortfolioCovidDataset..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
GO

SELECT * FROM PercentPopulationVaccinated