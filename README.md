# Malaysian-Population-Project

## Table of Contents
- [Project Download Link](#project-download-link)
- [Project Screenshots](#project-screenshots)
- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools](#tools)
- [Data Cleaning & Preparation](#data-cleaning-and-preparation)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Data Analysis](#data-analysis)
- [Results](#results)
- [Observations](#Observations)
- [Limitations](#limitations)

---
### Project Download Link
- [Click Here to Download the PowerBI file](#)
---

### <ins>Project Screenshots</ins>



---

### Project Overview

The aim of this project is to analyze the Malaysian Population since 1970 until 2024, identify population growth trends and patterns and analyse them from the perspective or ethnicity and gender.

### Data Sources

In this project, 1 CSV obtained from the [data.gov.my Website](https://data.gov.my/data-catalogue/population_malaysia) was utilized as listed below:

- population_malaysia.csv
- [Click Here to Download the CSV file](#)


### Tools
- Microsoft Excel Spreadsheet - Data formatting
- MySQL - Data Cleaning, Exploratory Data Analysis
- PowerBI Desktop - Dashboard Report Visualization



### Data Cleaning and Preparation

The initial data preparation phase included the following steps:
1. Data Inspection and Formatting (MS Excel)
   - Formatting the CSV file to the normal *Number* format without the 1000 separator for numerical values
   - Changing the date format to "yyyy-mm-dd" as per the MySQL format
   - Saving the file as *population_malaysia_formatted.csv* as copying it to the location of the new database in the MySQL Server in the appdata folder
     
2. Data Import (MySQL workbench)
   - Create a new database with a blank table that has matching column names and the appropriate data types to that of the CSV file

   ```
   CREATE DATABASE IF NOT EXISTS malaysian_population;

   USE malaysian_population;

   CREATE TABLE my_pop
   (
	  `date` DATE,
    sex VARCHAR(255),
    age VARCHAR(255),
    ethnicity VARCHAR(255),
    population DOUBLE
   );
   ```
 - Solving the Errors that appeared when trying to import the data which were:
   1. ERROR: Loading local data is disabled - this must be enabled on both the client and server sides
   2. LOAD DATA LOCAL INFILE file request rejected due to restrictions on access
   
   - **Solution:** Edit the connection, on the Connection tab, go to the 'Advanced' sub-tab, and in the 'Others:' box add the line 'OPT_LOCAL_INFILE=1'.
     
     
 - Proceed to use the query below to load the data into the database:
   ```
   LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Data/malaysian_population/population_malaysia_formatted.csv'
   INTO TABLE my_pop
   FIELDS TERMINATED BY ','
   IGNORE 1 LINES;
   ```
  
3. Data Cleaning
   ```
   -- I replaced some error values in the age column with the appropriate age range values
   UPDATE my_pop
   SET age = "5-9"
   WHERE age = "05-Sep"
   ;

   UPDATE my_pop
   SET age = "10-14"
   WHERE age = "Oct-14"
   ;

   ```

### Exploratory Data Analysis

EDA involved exploring the datasets to answer several key questions, namely:

1. What is the date range of the data?
2. What is the overall population of each year by gender?
3. What is the latest overall population (male and female combined)?
4. What is the ratio of male to female for each year?
5. Which age bracket has the highest and lowest population for the most recent 3 years?
6. What is the Year on Year growth of the population?
7. Which year had the highest and lowest population?
8. What is the population ratio between the 3 major ethnic groups in Malaysia in 2024?

### Data Analysis
Below are the MySQL queries used to obtain the answers to the questions above:
1. Using the MAX() and MIN() on the "date" column, I obtained the start and end date of the data set
  ```
  SELECT MIN(date), MAX(date)
  FROM my_pop;
  ```
2. I obtained my answer by filtering using the WHERE clause on the "age" "ethnicity" and "sex" columns and sorted the results in Descending order using the ORDER BY and DESC keyword
  ```
  SELECT*
  FROM my_pop
  WHERE age = "overall" AND ethnicity = "overall" AND sex != "both"
  ORDER BY `date` DESC, sex DESC;
  ```

3. Using the WHERE clause again I specify my desired criteria to get my answers
  ```
  SELECT*
  FROM my_pop
  WHERE sex = "both" AND age = "overall" AND ethnicity = "overall"
  ORDER BY `date` DESC;
  ```
4. Using a Common Table Expression (CTE) and a SELF JOIN operation, the male and female population was arranged to be in the same row to allow the ratio to be calculated more easily

  ```
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
  ```
5. By using the Rank() function and Over() function on the "population" column I made 2 columns of ranking inversed to each other by using the DESC keyword on one of them so as to obtain the top and bottom ranks
   when using the WHERE clause to specify for RankingTop = 1 and RankingBot = 1 for the most recent 3 years in the data and only Selecting RankingTop for the output.
  ```
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
  ```

6. Using the LEAD() window function, I brought forward the population of the previous year by 1 year to allow the current and previous year population to be on the same row for easier calculation

  ```
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
  ```

7. Using EMBEDDED QUERIES, the year can be extracted together with the aggregated population values to be displayed in the output

  ```
  SELECT
  YEAR(`date`),
  population 
  FROM my_pop
  WHERE population = (SELECT MAX(population) FROM my_pop WHERE sex = "both" AND ethnicity = "overall" AND age = "overall") 
  OR population = (SELECT MIN(population) FROM my_pop WHERE sex = "both" AND ethnicity = "overall" AND age = "overall")
  ;
  ```

8.Using the OVER() clause, I divided the 2024 population output with its lowest value to calculate the ratios between the 3 major ethnic groups in Malaysia

  ```
  SELECT
  YEAR(`date`) AS the_year,
  ethnicity,
  population,
  ROUND(population/(Min(population)OVER()),2) AS population_ratio
  FROM my_pop
  WHERE 
  YEAR(`date`) = 2024 AND sex = "both" AND age = "overall" AND ethnicity IN ("chinese", "indian", "bumi_malay")
  ;
  ```
 

### Results

The results output CSV files are as below:
1. [Click Here to Download Output 1](#)
2. [Click Here to Download Output 2](#)
3. [Click Here to Download Output 3](#)
4. [Click Here to Download Output 4](#)
5. [Click Here to Download Output 5](#)
6. [Click Here to Download Output 6](#)
7. [Click Here to Download Output 7](#)
8. [Click Here to Download Output 8](#)


### Observations:

Based on the analysis, it was observed that:
1. The population has grown by more than 3 times since 1970 till 2024
2. The ratio between the 3 major ethnic groups namely Bumi_Malay, Chinese, and Indian are 8.88 : 3.42 : 1.
3. For the years 2022 to 2024, the age bracket with the highest and lowest population are respectively the "20-24" and "85+" age brackets.
4. The Male to Female ratio shows a general increasing trend from around 1.02 to 1.11
5. For the Year on Year (YoY) population growth, the trend shows a relatively stable fluctuation of above 2 from 1970 to 2004 which is then followed by a gradual decline from 2005 to 2018 with the exception of 2013 which had a 2.38 YoY growth.
6. The YoY growth trend shows a sharp drop in 2019 and 2020 likely due to the COVID-19 pandemic which struck Malaysia towards the end of 2019. The 2020 YoY growth dropped to the negative level of -0.23 for the first time.
7. A surprising or interesting observation on the population when analyzed based on gender revealed that only the Female population saw a reduction of about 277,000 while the male population still saw an increase in 2020.


### Limitations

- Values for breakdowns may be slightly different to totals when summed, due to rounding to one decimal place. 
- Furthermore, caution should be exercised when using the dataset in full because the granularity of Malaysia's population data has been deepened over the years. Specficially, there are 3 differing ranges of granularity as follows:
  1. The data from 1991 onwards is the most granular, with ethnic group breakdowns providing differentiation between Malay and Other Bumiputera, as well as Other Citizen and Other Non-Citizen. Furthermore, the oldest age category is 85+, i.e. 85 years and above.
  2. The data from 1980-1990 contains a breakdown by ethnic group, but without differentiation between Malay and Other Bumiputera (i.e. there is only one Bumiputera category), or Other Citizen and Other Non-Citizen (i.e. there is only one residual category, Other).       3. Furthermore, the 85+ age group is not present; the oldest age category is 80+.
- For data from 1970-1979, there is no breakdown by ethnic group. Furthermore, the 75+, 80+ and 85+ age groups are not present; the oldest age category is 70+.
- An accurate explanation for the precise reason for the visible fall in only the female population cannot be made as more data is needed to investigate the cause.

