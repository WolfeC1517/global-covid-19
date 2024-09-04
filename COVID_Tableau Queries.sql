
USE PortfolioProject
GO



-- 1.

SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths as FLOAT)) AS total_deaths,
	SUM(CAST(new_deaths as FLOAT))/SUM(new_cases) AS mortality_rate

FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2




-- 2.

SELECT
	location,
	SUM(CAST(new_deaths AS FLOAT)) AS total_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL AND
	location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_death_count DESC




-- 3.

SELECT
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	CAST(MAX(total_cases)/population AS FLOAT) AS percent_population_infected
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY
	location,
	population
ORDER BY MAX(total_cases)/population DESC


-- 4.

SELECT
	location,
	population,
	FORMAT(date, 'yyyy/MM/dd') AS date,
	MAX(total_cases) AS highest_infection_count,
	MAX(total_cases)/population AS percent_population_infected
FROM PortfolioProject..CovidDeaths$
-- WHERE location LIKE '%states%'
GROUP BY
	location,
	population,
	date
ORDER BY
	percent_population_infected DESC





