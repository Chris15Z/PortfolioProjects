--Hello There! This Project is to explore the Data about Covid 19 found in the page 'Our World in Data' To practice SQL and get some insights about it

--Exploring the Dataset of Covid

SELECT *
FROM PortfolioProject..OwidCovidData
ORDER BY 3,4

--Now it is time to select the data what we are going to use for the analysis

SELECT continent, location, date, new_cases, total_cases, new_deaths, total_deaths, total_vaccinations
FROM PortfolioProject..OwidCovidData
ORDER BY 2,3

--We need to clean some data before starting to make operations, because there are some 0 that can
--show the divided by zero error

Delete
FROM PortfolioProject..OwidCovidData
WHERE total_cases = 0

--Once we have the data that we are going to be using, lets compare the total cases vs the total deaths
--We need to convert the data of total deaths and total cases to float because is in varchar

SELECT location, date, total_cases, total_deaths, (Convert(float, total_deaths) / Convert(float, total_cases))*100 AS DeathPercentage
FROM PortfolioProject..OwidCovidData
ORDER BY 1,2,3

--To see the percentage of the population of the country that got covid we do this

DELETE
FROM PortfolioProject..OwidCovidData
WHERE cast(population as float) = 0

--I had to delete that because there was the same problem of divided by zero

SELECT location, date, total_cases, population, (Convert(float, total_cases) / Convert(float, population))*100 AS CovidInfectionPercentage
FROM PortfolioProject..OwidCovidData
ORDER BY 1,2,3

--Now lets see the countries with the highest infection rate compared with their population
--With this we can see the total of the population that got covid and the percentage that represents

SELECT location, population, MAX(Convert(int, total_cases)) AS HighestInfection, MAX(Convert(float, total_cases) / Convert(float, population))*100 AS CovidInfectionPercentage
FROM PortfolioProject..OwidCovidData
GROUP BY location, population
ORDER BY CovidInfectionPercentage DESC

--We can see the highest dead per population of the countries

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..OwidCovidData
GROUP BY location
ORDER BY TotalDeathsCount DESC

--And we can break down things only by continent because location includes continents too

--There is a problem, the data has blank cells when we talk about continent, and we can see them here

SELECT continent, total_deaths, MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..OwidCovidData 
WHERE continent = ''
GROUP BY continent, total_deaths

--Then we proceed to eliminate them to clean the data

DELETE
FROM PortfolioProject..OwidCovidData
WHERE continent = ''

--And now we can se the total of deaths per continent without problems

SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..OwidCovidData
GROUP BY continent
ORDER BY TotalDeathsCount DESC

--We can see the global numbers of diferent things on the following way
--We need to use the new data because the sum of the new is the total

SELECT SUM(convert(int,new_cases)) AS TotalCases, SUM(convert(int,new_deaths)) AS TotalDeaths, SUM(convert(float,new_deaths))/SUM(convert(float,new_cases)) *100 AS DeathPercentage
FROM PortfolioProject..OwidCovidData

--Now lets see the total population vs vaccinated people by location
--We use partition by because we want to see the evolution of the people vaccinated

SELECT continent, location, date, population, new_vaccinations, SUM(CONVERT(float, new_vaccinations)) 
OVER (Partition by location ORDER BY location,date) AS RollingPeopleVaccinated
FROM PortfolioProject..OwidCovidData
ORDER BY 2,3

--In some cases we have that the people vaccinated is more than the population, one hipotesis
--could be that some people traveled to that country to get the vaccine of covid

--Now lets going to practice some CTEs with other calculations
--You cant use ORDER BY with CTEs because is going to give you an error

WITH ContinentInfo AS 
(
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathsCount, 
MAX(convert(float, total_cases)) AS TotalCovidCases,
MAX(convert(float, total_vaccinations)) AS TotalVaccinated
FROM PortfolioProject..OwidCovidData
GROUP BY continent
--ORDER BY TotalDeathsCount DESC
)
SELECT *, (TotalDeathsCount/TotalCovidCases)*100 AS DeathRate
FROM ContinentInfo
ORDER BY DeathRate DESC

--Now is time for Temp Tables

DROP TABLE IF EXISTS #CovidDataForAll 
CREATE TABLE #CovidDataForAll
(
Continent nvarchar(255),
Location nvarchar (255),
Population numeric,
Date datetime,
Vaccinations numeric
)

INSERT INTO #CovidDataForAll
SELECT continent, location, population, date, convert(float,new_vaccinations)
FROM PortfolioProject..OwidCovidData

SELECT *
FROM #CovidDataForAll

--And at this point we are going to create views to store data for later visualizations
--ORDER BY can not be used on views

--1) Covid Infection Percentage by location

CREATE VIEW CovidPercentageLocation AS
SELECT location, population, MAX(Convert(int, total_cases)) AS HighestInfection, MAX(Convert(float, total_cases) / Convert(float, population))*100 AS CovidInfectionPercentage
FROM PortfolioProject..OwidCovidData
GROUP BY location, population
--ORDER BY CovidInfectionPercentage DESC

--2) Global data by continents

CREATE VIEW CovidGlobalData AS
WITH ContinentInfo AS 
(
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathsCount, 
MAX(convert(float, total_cases)) AS TotalCovidCases,
MAX(convert(float, total_vaccinations)) AS TotalVaccinated
FROM PortfolioProject..OwidCovidData
GROUP BY continent
--ORDER BY TotalDeathsCount DESC
)
SELECT *, (TotalDeathsCount/TotalCovidCases)*100 AS DeathRate
FROM ContinentInfo
--ORDER BY DeathRate DESC

