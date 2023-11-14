SELECT *
FROM PortfolioProject..['owid-covid-data$']	
order by 3,4

	
--looking at total cases vs total deaths 
select Location,date,total_cases,total_deaths,(CONVERT(INT,total_deaths)/CONVERT(INT,total_cases))*100 AS DeathPourcentage
from PortfolioProject..['owid-covid-data$']
where location like '%Tunisi%' and total_cases <> 0 and total_deaths <> 0
order by 1,2

--looking at total cases vs population 
select Location,date,population,total_cases,--(CAST(total_cases as int)/(CAST(Population as int))*100 as PercentPopulationInfected 
from PortfolioProject..['owid-covid-data$']
where location like '%Tunisi%'
order by 1,2

--looking at counties with highest infection rates compered to Population 
select Location,Population,MAX(total_cases) as HighestInfectionCount 
--,MAX((total_deaths/total_cases))*100 as PercentPopulationInfected
from PortfolioProject..['owid-covid-data$']
--where location like '%Tunisi%'
GROUP BY Location,Population
order by 1,2

-- showing the countries with highest death count per Population 
select Location,MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..['owid-covid-data$']
--where location like '%Tunisi%'
GROUP BY Location
order by TotalDeathCount desc

--selecting by country
select continent,MAX(total_deaths) as maxdeaths 
from PortfolioProject..['owid-covid-data$']
--where location like '%Tunisi%'
where continent is not null 
GROUP BY continent,total_deaths
order by total_deaths desc


/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..['owid-covid-data$']
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..['owid-covid-data$']
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location,date, total_cases,total_deaths

  CASE
        WHEN CONVERT(int, Total_Cases) = 0 THEN 0  -- Handle division by zero
        ELSE (CONVERT(int, Total_Deaths) * 100.0) / CONVERT(int, Total_Cases)
  END AS DeathPercentage

From PortfolioProject..['owid-covid-data$']
Where location like '%Tunisi%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From From PortfolioProject..['owid-covid-data$']
--Where location like '%Tunisi%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..['owid-covid-data$']
--Where location like '%Tunisi%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..['owid-covid-data$']
--Where location like '%Tunisi%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..['owid-covid-data$']
--Where location like '%Tunisi%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths AS INT)) as total_deaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
From PortfolioProject..['owid-covid-data$']
--Where location like '%Tunisi%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


