USE malaysian_population;

SELECT *
FROM my_pop;



-- DATA CLEANING 
-- I replaced some error values in the age column with the appropriate age range values
UPDATE my_pop
SET age = "5-9"
WHERE age = "05-Sep"
;

UPDATE my_pop
SET age = "10-14"
WHERE age = "Oct-14"
;


/*
Questions to answer:
1. What is the date range of the data?
2. What is the overall population of each year by gender?
3. What is the latest overall population (male and female combined)?
4. What is the ratio of male to female for each year?
5. Which age bracket has the highest and lowest population for the most recent 3 years?
6. What is the Year on Year growth of the population?
7. Which year had the highest and lowest population?
8. What is the population ratio between the 3 major ethnic groups in Malaysia in 2024?
*/

-- ANSWER 1: The date range is from 1970 to 2024
SELECT MIN(date), MAX(date)
FROM my_pop;

-- ANSWER 2
SELECT*
FROM my_pop
WHERE age = "overall" AND ethnicity = "overall" AND sex != "both"
ORDER BY `date` DESC, sex DESC;

-- ANSWER 3
SELECT*
FROM my_pop
WHERE sex = "both" AND age = "overall" AND ethnicity = "overall"
ORDER BY `date` DESC;

-- ANSWER 4
-- Using a CTE and a SELF JOIN, the male and female population was arranged in the same row to allow the ratio to be calculated more easily
WITH CTE_pop_ratio AS 
(
SELECT
YEAR(`date`) AS the_year, 
sex,
ethnicity,
(SELECT population WHERE sex!= "male" AND age = "overall" AND ethnicity = "overall") AS population_f,
(SELECT population WHERE sex!= "female" AND age = "overall" AND ethnicity = "overall") AS population_m
FROM my_pop
WHERE sex!= "both" AND age = "overall" AND ethnicity = "overall"
)
SELECT 
A.the_year, 
A.population_m,
B.population_f,
ROUND((A.population_m/B.population_f),2) AS m_f_ratio
FROM CTE_pop_ratio A
JOIN CTE_pop_ratio B
	ON A.the_year = B.the_year
WHERE A.population_m IS NOT NULL 
	AND B.population_f IS NOT NULL
ORDER BY the_year DESC;


-- ANSWER 5

-- The query below returns the top and bottom ranks

WITH CTE_ranking AS
(
SELECT
YEAR(`date`) AS the_year,
sex,
age,
ethnicity,
population,
RANK() OVER (PARTITION BY `date` ORDER BY population DESC) AS RankingTop,
RANK() OVER (PARTITION BY `date` ORDER BY population ASC) AS RankingBot
FROM my_pop
WHERE age != "overall" AND ethnicity = "overall" AND sex = "both"
)
SELECT the_year, age, population, RankingTop
FROM CTE_ranking
WHERE RankingTop = 1 AND the_year IN (2024,2023,2022) 
	OR RankingBot = 1 AND the_year IN (2024,2023,2022)
ORDER BY the_year DESC, population DESC
;





-- The query below returns the top 3 and bottom 3 population for the years 2024, 2023, and 2022
/*
WITH CTE_ranking AS
(
SELECT
YEAR(`date`) AS the_year,
sex,
age,
ethnicity,
population,
RANK() OVER (PARTITION BY `date` ORDER BY population DESC) AS RankingTop,
RANK() OVER (PARTITION BY `date` ORDER BY population ASC) AS RankingBot
FROM my_pop
WHERE age != "overall" AND ethnicity = "overall" AND sex = "both"
)
SELECT the_year, age, population, RankingTop
FROM CTE_ranking
WHERE RankingTop IN (1,2,3) AND the_year IN (2024,2023,2022) 
	OR RankingBot IN (1,2,3) AND the_year IN (2024,2023,2022)
ORDER BY the_year DESC, population DESC
;
*/


-- The query below returns the top 3 ranks for years 2024, 2023 and 2022
/*
WITH CTE_ranking AS
(
SELECT
YEAR(`date`) AS the_year,
sex,
age,
ethnicity,
population,
ROW_NUMBER () OVER (PARTITION BY `date` ORDER BY population DESC) AS Ranking
FROM my_pop
WHERE age != "overall" AND ethnicity = "overall" AND sex = "both"
)
SELECT the_year, age, population, Ranking
FROM CTE_ranking
WHERE Ranking IN (1,2,3) AND the_year IN (2024,2023,2022)
ORDER BY the_year
;
*/



-- ANSWER 6
WITH CTE_YOY AS
(
SELECT 
YEAR(`date`) the_year,
ethnicity,
age,
population AS current_yr_pop,
LEAD(population)OVER(PARTITION BY age ORDER BY `date` DESC) AS pre_yr_pop
FROM my_pop
WHERE sex = "both" AND ethnicity = "overall" AND age = "overall"
ORDER BY age, the_year DESC
)
SELECT the_year, current_yr_pop, pre_yr_pop, ROUND(100*((current_yr_pop-pre_yr_pop)/pre_yr_pop),2) AS YOY
FROM CTE_YOY;




-- ANSWER 7
-- Using EMBEDDED QUERIES, the year can be extracted together with the aggregated population values
SELECT
YEAR(`date`), population 
FROM my_pop
WHERE population = (SELECT MAX(population) FROM my_pop WHERE sex = "both" AND ethnicity = "overall" AND age = "overall") 
OR population = (SELECT MIN(population) FROM my_pop WHERE sex = "both" AND ethnicity = "overall" AND age = "overall")
;

/* The query below can extract the aggregate of an aggregated function via nested queries

SELECT MAX(`MAX(population)`), MIN(`MAX(population)`)
FROM
(SELECT
YEAR(`date`) the_year,
MAX(population)
FROM my_pop
WHERE sex = "both" AND ethnicity = "overall" AND age = "overall"
GROUP BY the_year
ORDER BY age, the_year DESC) AS Agg_Table;
*/

-- ANSWER 8
-- USING WINDOW FUNCTIONS, I divided the 2024 population output with its lowest value to extract the ratios between the 3 ethnic groups

SELECT
YEAR(`date`) AS the_year,
ethnicity,
population,
ROUND(population/(Min(population)OVER()),2) AS population_ratio
FROM my_pop
WHERE 
YEAR(`date`) = 2024 AND sex = "both" AND age = "overall" AND ethnicity IN ("chinese", "indian", "bumi_malay");
 

/* This original query was able to produce the population of the 3 major ethnic groups in MY for 2024. Modifications of this query made to produce the above query

SELECT
YEAR(`date`) AS the_year, 
sex, 
age, 
ethnicity, 
population
FROM my_pop
WHERE 
YEAR(`date`) = 2024 AND sex = "both" AND age = "overall" AND ethnicity IN ("chinese", "indian", "bumi_malay")
*/

