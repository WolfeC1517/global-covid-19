
USE PortfolioProject
GO

-- Looking at Total Cases vs Total Deaths
-- Percentage Likelihood of Death on infection
-- Sorted by location and date

SELECT 
	location,
	FORMAT(date, 'yyyy/MM/dd') AS report_date,
	total_cases,
	total_deaths,
	FORMAT(ROUND(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT), 4), 'P2') AS mortality_rate
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL 
ORDER BY 
	location, report_date

	
-- Looking at Total number of COVID Cases vs Population in the U.S.
-- Shows what percentage of the population contracted COVID
SELECT 
	location,
	FORMAT(date, 'yyyy/MM/dd') AS report_date,
	total_cases,
	population,
	FORMAT(ROUND(CAST(total_cases AS FLOAT)/population, 4), 'P2') AS infection_rate
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL AND
	location = 'United States'
ORDER BY 
	location,
	report_date




-- Show the infection rate of each country and order them by the highest rate of infection

SELECT 
	location,
	population,
	MAX(CAST(total_cases AS FLOAT)) AS highest_infection_count,
	FORMAT(ROUND(MAX(CAST(total_cases AS FLOAT))/population, 4), 'P2') AS highest_infection_rate
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location,
	population
ORDER BY 
	MAX(CAST(total_cases AS FLOAT))/population DESC





-- Shows the Death count per country and sorts them from highest to lowest

SELECT 
	location,
	MAX(CAST(total_deaths AS FLOAT)) AS total_death_count
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location
ORDER BY 
	total_death_count DESC





-- Show max death rate of each country per capita



SELECT 
	location,
	population,
	MAX(CAST(total_deaths AS FLOAT)) AS total_death_count,
	FORMAT(ROUND(MAX(CAST(total_deaths AS FLOAT)/population), 4), 'P2') AS max_mortality_rate_per_capita
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location,
	population
ORDER BY 
	MAX(CAST(total_deaths AS FLOAT)/population) DESC





-- Show max death rate of each country per case


SELECT 
	location,
	MAX(CAST(total_cases AS FLOAT)) AS total_case_count,
	MAX(CAST(total_deaths AS FLOAT)) AS total_death_count,
	FORMAT(ROUND(MAX(CAST(total_deaths AS FLOAT))/MAX(CAST(total_cases AS FLOAT)), 4), 'P2') AS max_mortality_rate_per_case
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location
ORDER BY 
	MAX(CAST(total_deaths AS FLOAT))/MAX(CAST(total_cases AS FLOAT)) DESC




-- Show max death rate of each country per capita & per case


SELECT 
	location,
	population,
	MAX(CAST(total_deaths AS FLOAT)) AS total_death_count,
	FORMAT(ROUND(MAX(CAST(total_deaths AS FLOAT)/population), 4), 'P2') AS max_mortality_rate_per_capita,
	MAX(CAST(total_cases AS FLOAT)) AS total_case_count,
	FORMAT(ROUND(MAX(CAST(total_deaths AS FLOAT))/MAX(CAST(total_cases AS FLOAT)), 4), 'P2') AS max_mortality_rate_per_case
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location,
	population
ORDER BY 
	MAX(CAST(total_deaths AS FLOAT))/MAX(CAST(total_cases AS FLOAT)) DESC


-- Data by Continent


SELECT
	location AS continent_totals,
	MAX(CAST(total_deaths AS FLOAT)) AS total_death_count
FROM
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NULL  -- The original table has the continent totals listed under location with null in the continent column
GROUP BY 
	location
ORDER BY
	total_death_count DESC



-- Global mortality rate listed by date. CREATE VIEW is used to compare with the second calculation.
-- DROP VIEW includeded for convinience

DROP VIEW IF EXISTS global_mortality_rate
GO
CREATE VIEW global_mortality_rate AS
SELECT 
	FORMAT(date, 'yyyy/MM/dd') AS report_date,
	location,
	total_cases,
	total_deaths,
	FORMAT(ROUND(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT), 4), 'P2') AS mortality_rate
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	location = 'world'
GO


-- Same as the last but rather than use the global number provided in the report, I calculated the sum of
-- all cases in the report. Not as accurate as using the global numbers above, but good for double checking.
-- Again CREATE VIEW is used for comparison.

DROP VIEW IF EXISTS summed_mortality_rate
GO
CREATE VIEW summed_mortality_rate AS
SELECT 
	FORMAT(date, 'yyyy/MM/dd') AS report_date,
	SUM(CAST(total_cases AS FLOAT)) AS global_cases,
	SUM(CAST(total_deaths AS FLOAT)) AS global_deaths,
	FORMAT(ROUND(SUM(CAST(total_deaths AS FLOAT))/SUM(CAST(total_cases AS FLOAT)), 4), 'P2') AS mortality_rate
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	date
GO

-- Both VIEWs are compared and there is found to be less than a 0.1% difference between the two.

SELECT
	glo.report_date,
	glo.total_cases,
	summ.global_cases AS summed_cases,
	glo.total_deaths,
	summ.global_deaths AS summed_deaths,
	glo.mortality_rate,
	summ.mortality_rate AS summed_mortality_rate

FROM PortfolioProject..global_mortality_rate AS glo
JOIN PortfolioProject..summed_mortality_rate AS summ
	ON glo.report_date = summ.report_date
ORDER BY 
	report_date


-- Shows the weekly reported number of new cases and deaths. The report shows us that it was updated weekly on Sunday.
SELECT
	FORMAT(date, 'yyyy/MM/dd'),
	FORMAT(date, 'dddd') AS day_of_week,
	SUM(new_cases) AS global_new_cases,
	SUM(new_deaths) AS global_new_deaths
FROM
	PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY
	date
ORDER BY
	1,
	2


-- Analysis of population vs Vaccinations by location and date

SELECT 
	dea.continent, 
	dea.location, 
	FORMAT(dea.date, 'yyyy/MM/dd'), 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_counter
FROM PortfolioProject..CovidVaccinations$ vac
JOIN PortfolioProject..CovidDeaths$ dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- Used CTE to create a rolling vaccination counter by location and date.


WITH  PopVsVac (continent, location, date, population, new_vaccinations, rolling_vaccination_counter)
AS (
SELECT 
	dea.continent, 
	dea.location, 
	FORMAT(dea.date, 'yyyy/MM/dd'),
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_counter
FROM PortfolioProject..CovidVaccinations$ vac
JOIN PortfolioProject..CovidDeaths$ dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,
	FORMAT(ROUND(rolling_vaccination_counter/population, 4), 'P2') AS percent_vaccinated
FROM PopVsVac
ORDER BY
	location,
	date


-- The same CTE however I used the code to list the maximum number of vaccines by country.


WITH  max_vac (continent, location, date, population, new_vaccinations, rolling_vaccination_counter)
AS (
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_counter
FROM PortfolioProject..CovidVaccinations$ vac
JOIN PortfolioProject..CovidDeaths$ dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT
	location,
	population,
	MAX(rolling_vaccination_counter) AS max_number_vaccinations,
	FORMAT(ROUND(MAX(rolling_vaccination_counter)/population, 4), 'P2') AS percent_vaccinated
FROM max_vac
GROUP BY
	location,
	population
ORDER BY
	MAX(rolling_vaccination_counter)/population DESC,
	location




-- Temp Table; same information as above but stored as a table that I can use later.

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_vaccination_counter numeric
	)

INSERT INTO #percent_population_vaccinated

SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_counter

	

FROM PortfolioProject..CovidVaccinations$ vac
JOIN PortfolioProject..CovidDeaths$ dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *,
	FORMAT(ROUND(rolling_vaccination_counter/population, 4), 'P2') AS percent_vaccinated
FROM #percent_population_vaccinated




-- Creating a VIEW to store data for later data visualizations

DROP VIEW IF EXISTS percent_population_vaccinated
GO
CREATE VIEW percent_population_vaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination_counter

FROM PortfolioProject..CovidVaccinations$ vac
JOIN PortfolioProject..CovidDeaths$ dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GO