/*
Covid 19 Data Exploration Project (Dataset until 5th July 2023) 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Converting Data Types

*/

--selecting the data
select Location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths2023
order by 1,2

--Comparing total cases and total deaths to show likelihood of dying if you are infected with covid in USA
select Location, date, cast(total_cases as float) as totalcases, cast(total_deaths as float) as totaldeaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as deathpercentage
from CovidDeaths2023
where Location = 'United states'
and continent is not null
order by 2

--Comparing population and total cases to show what percentage of population infected with Covid
--30% of total population has been infected with COVID in United States until 5th July 2023
select Location, date, population, total_cases, (total_cases/population)*100 as infectedpercentage
from CovidDeaths2023
where Location = 'United states' and continent is not null
order by 2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(cast(total_cases as int)) as HighestInfectionCount,  Max((cast(total_cases as int)/population))*100 as PercentPopulationInfected
From CovidDeaths2023
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death count compared to population
--United States, Brazil and India ranked among the top 3 countries in Deathcount
Select Location,population, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths2023
Where continent is not null 
Group by Location, population
order by TotalDeathCount desc

--Countries with Highest Death percentage compared to population
--Peru has lost its 0.6% population to COVID
Select Location,population, MAX(cast(Total_deaths as int)) as TotalDeathCount, (MAX(cast(Total_deaths as int))/population)*100 as maxdeathpercentage
From CovidDeaths2023
Where continent is not null 
Group by Location, population
order by maxdeathpercentage desc

--Showing contintents with the highest death count

SELECT continent, SUM(maxdeathcount) AS continentdeathcount
FROM (
    SELECT continent, location, MAX(cast(total_deaths as int)) AS maxdeathcount
    FROM CovidDeaths2023
    WHERE continent IS NOT NULL
    GROUP BY continent, location
)maxdeathsperlocation
GROUP BY continent
order by continentdeathcount desc

--Comparing population and covid tests done  using Temp table

DROP Table if exists #totaltests
Create Table #totaltests
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_tests numeric,
RollingPeopletests numeric
)

Insert into #totaltests
Select death.continent, death.location, death.date, death.population, vaccine.new_tests,
SUM(cast(vaccine.new_tests as float)) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopletests
From CovidDeaths2023 death
Join CovidVaccinations2023 vaccine
	On death.location = vaccine.location
	and death.date = vaccine.date
where death.continent is not null
order by 1,2

Select *
From #totaltests

--Number of vaccinations given to people each location on daily basis
Select death.continent, death.location, death.date, death.population, vaccine.new_vaccinations,
SUM(cast(vaccine.new_vaccinations as float)) OVER (Partition by death.Location Order by death.location, death.Date) as RollingVaccinations
From CovidDeaths2023 death
Join CovidVaccinations2023 vaccine
	On death.location = vaccine.location
	and death.date = vaccine.date
where death.continent is not null
order by 2,3

--calculating the percentage of people fullyvaccinated, partially vaccinated and not vaccinated using CTE
with vaccinationstatus (continent, location, population, peoplevaccinated, peoplefullyvaccinated, peoplepartiallyvaccinated, peoplenotvaccinated)
as (
Select death.continent, death.location, death.population, max(cast(vaccine.people_vaccinated as float)) as peoplevaccinated, 
max(convert(float,vaccine.people_fully_vaccinated))as peoplefullyvaccinated, 
(max(cast(vaccine.people_vaccinated as float))-max(convert(float,vaccine.people_fully_vaccinated))) as peoplepartiallyvaccinated,
(death.population-(max(cast(vaccine.people_vaccinated as float)))) as peoplenotvaccinated
from CovidDeaths2023 death
Join CovidVaccinations2023 vaccine
	On death.location = vaccine.location
where death.continent is not null
group by death.continent, death.location, death.population
)
select *, round((peoplefullyvaccinated/population)*100,2) as fullyvaccinatedpercent, 
round((peoplepartiallyvaccinated/population)*100,2) as partialvaccinatedpercent, round((peoplenotvaccinated/population)*100,2) as notvaccinatedpercent
from vaccinationstatus
order by 1,2

--Global numbers
--Newcases, newdeaths per day across the world
Select max(death.population) as population, max(cast(death.total_cases as float)) as totalcovidcases, 
max(cast(death.total_deaths as float)) as totalcoviddeaths, max(cast(vaccine.total_vaccinations as float)) as totalvaccines
From CovidDeaths2023 Death
join CovidVaccinations2023 Vaccine
on death.location = Vaccine.location
where death.location = 'world'