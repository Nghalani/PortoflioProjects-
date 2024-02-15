--Checking if tables are loaded correclty. 

	--SELECT * FROM CovidData..Deaths
	--order by 3,4 


	--SELECT * FROM CovidData..Vaccinations
	--order by 3,4 

--Checking covid deaths vs total cases in South Africa 
-- error that total deaths and cases are characters and not integers, fixed using  CAST to INT
ALTER TABLE CovidData..Deaths
ALTER COLUMN total_cases INT

ALTER TABLE CovidData..Deaths
ALTER COLUMN total_deaths INT

ALTER TABLE CovidData..Deaths
ALTER COLUMN new_deaths INT

ALTER TABLE CovidData..Deaths
ALTER COLUMN new_cases INT

ALTER TABLE CovidData..Vaccinations
ALTER COLUMN new_vaccinations BIGINT

ALTER TABLE CovidData..Vaccinations
ALTER COLUMN date DATETIME

ALTER TABLE CovidData..deaths
ALTER COLUMN date DATETIME


	SELECT location, date, total_cases, total_deaths,(total_deaths / total_cases ) * 100 AS DeathPercentage
	FROM CovidData..Deaths
	WHERE location LIKE '%south africa%' 
	order by 1,2

	--First case was recorded on the 8th of March and the first death was the 29th of March. 


--Checking total cases vs the population of South Afrcia 

	SELECT location, date,population, total_cases, (total_cases/population ) * 100 AS Percent_of_Population_Infected  
	FROM CovidData..Deaths
	WHERE location LIKE '%south africa%' 
	order by 1,2

	-- It took almost 5 months for 1% of South Africa to contract Covid.   

-- Where does South Africa rank when to comes to countries with the highest infection rate compared to population
	SELECT 
		location, 
		population, 
		MAX(total_cases) AS Highest_Infection_count, 
		MAX(total_cases /population ) * 100 AS Percent_of_Population_Infected
	FROM CovidData..Deaths 
	WHERE population >= 50000000 AND Continent is not null
	GROUP BY location, population
	ORDER BY Percent_of_Population_Infected DESC 
	



	--South Africa ranked number 15 0f all coutries in terms of total cases of covid vs population. This was for cases where the population is 
	-- equal to 50 000 000 or more. 

-- Where does South Africa rank when to comes to countries with the highest death rate compared to population

	SELECT 
		location, 
		population,
		MAX(total_deaths) AS Highest_Infection_count, 
		MAX(total_deaths /population ) * 100 AS Percent_of_Population_deaths
	FROM CovidData..Deaths 
	WHERE population >= 50000000 AND Continent is not null
	GROUP BY location, population
	ORDER BY Percent_of_Population_deaths DESC
	

	

--Global Numbers, new cases per date 
	SELECT date, SUM(new_cases) as Total_cases, 
	SUM(new_deaths) as Total_deaths,
	Nullif(sum(new_deaths), 0)/nullif(sum(new_cases), 0)*100 as death_percentage 
	FROM CovidData..Deaths 
	WHERE continent is not null
	GROUP BY date 
	ORDER BY 1,2

--Join Covid cases dataset with Vaccinations Dataset 

SELECT * FROM CovidData..Deaths dea
JOIN CovidData..Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 


--Analysis new vaccinations on a daily basis  
	-- Have to use a CTE 

WITH Population_Vaccinated AS
(
SELECT dea.Continent, dea.Location,dea.Date, dea.Population, vac.New_vaccinations,
	SUM(vac.new_vaccinations) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Total_vaccinations
FROM CovidData..Deaths dea
JOIN CovidData..Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not null)

SELECT *,(Total_vaccinations/population)*100  AS Percentage_Vaccianted 
FROM  Population_Vaccinated

	--Another way would be to use a TEMP Table
DROP TABLE IF EXISTS #Population_Vaccinated
CREATE TABLE #Population_Vaccinated
(Continent NVARCHAR(255),
location NVARCHAR(255),
Date DATETIME, 
Population NUMERIC,
New_vaccinations NUMERIC,
Total_vaccinations  NUMERIC
)

INSERT INTO  #Population_Vaccinated
SELECT dea.Continent, dea.Location,dea.Date, dea.Population, vac.New_vaccinations,
	SUM(vac.new_vaccinations) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Total_vaccinations
		FROM CovidData..Deaths dea
JOIN CovidData..Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not null

SELECT *,(Total_vaccinations/population)*100
FROM #Population_Vaccinated

--Use View to store data that will be used in another analysis
CREATE VIEW  Population_Vaccinated AS
SELECT dea.Continent, dea.Location,dea.Date, dea.Population, vac.New_vaccinations,
	SUM(vac.new_vaccinations) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Total_vaccinations
		FROM CovidData..Deaths dea
JOIN CovidData..Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not null