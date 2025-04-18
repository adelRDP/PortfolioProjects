
	--Let's take a look into our Tables

	SELECT *
	FROM CovidDeaths
	ORDER BY 3,4

	SELECT *
	FROM CovidVaccinations
	ORDER BY 3,4

	-- Select the Data that i'm gonna be using

	SELECT location, date, total_cases, new_cases, total_deaths, population
	FROM PortfolioProject..CovidDeaths
	ORDER BY 1,2

	-- Looking at TotalCases vs Total Deaths (aka DeatRate)
	-- Shows likelihood of dying if a person contracted Covid in their country!
	
	Select location, date, total_cases,total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 as DeathRate
	FROM PortfolioProject..CovidDeaths
	--WHERE location LIKE 'IRAN'
	WHERE continent IS NOT NULL
	ORDER BY 1,2

	-- Looking at Countries with highest Infection Rate	(infection / population)

	SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 as [Infection Rate]
	FROM PortfolioProject..CovidDeaths
	-- WHERE location LIKE 'IRAN'
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY [Infection Rate] DESC

	-- Showing Countries with highest Death Count per Population

	SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL -- exclude the entire continent rows, decrease redundancy
	GROUP BY location
	ORDER BY TotalDeathCount DESC


	-- Bringing in Continents!

	SELECT continent, SUM(max_deaths) AS TotalDeathCount
	FROM (
	SELECT continent, location, MAX(CAST(total_deaths AS INT)) AS max_deaths
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, location
	) AS sub
	GROUP BY continent
	ORDER BY TotalDeathCount DESC


	-- Daily Death Rate

	SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) total_deaths ,
	round(SUM(cast(new_deaths as int))/SUM(new_cases)*100, 3)  DeathRate
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY date
	ORDER BY 1,2
	

	-- Looking at Total Population vs Vaccination
	
	SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
	SUM(CAST(V.new_vaccinations AS INT)) OVER (PARTITION BY D.LOCATION ORDER BY v.location, d.date) [So far Vaccinated]
	FROM PortfolioProject..CovidDeaths D
	JOIN PortfolioProject..CovidVaccinations V
	ON D.location = V.location AND D.date = V.date
	WHERE D.continent IS NOT NULL
	ORDER BY 2,3

	-- Using CTE to calculate percentage

	WITH VaccinatedRate (Continent, Location, Date, Population, New_vaccinations,[So far Vaccinated])
	AS(
	SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
	SUM(CAST(V.new_vaccinations AS INT)) OVER (PARTITION BY D.LOCATION ORDER BY v.location, d.date) [So far Vaccinated]
	FROM PortfolioProject..CovidDeaths D
	JOIN PortfolioProject..CovidVaccinations V
	ON D.location = V.location AND D.date = V.date
	WHERE D.continent IS NOT NULL
	)
	SELECT *,([So far Vaccinated]/population)*100 [Total Vaccinated %]
	FROM VaccinatedRate
	ORDER BY 2,3

	-- VIEW countries done best in terms of Vaccination and Testing

	CREATE VIEW CountriesVacRep AS
	SELECT  location , MAX(CONVERT(INT,total_vaccinations))[Total Vaccination],MAX(CONVERT(int,total_tests))[Total tests],
	MAX(CONVERT(FLOAT,people_vaccinated_per_hundred)) people_vaccinated_per_hundred
	FROM PortfolioProject..CovidVaccinations
	WHERE continent is not null
	GROUP BY location

	SELECT *
	FROM CountriesVacRep
	ORDER BY location
