-- THE WORLD HEALTH DATABASE: The first database contains comprehensive world health statistics, including data on various countries and a range of key factors for analysis, such as average life expectancy, infant mortality, neonatal mortality, and more. 
-- Below are examples of queries that can be used to extract and analyze the required information effectively -- 

-- 1/ Retrieve the top 5 countries with the highest life expectancy in any given year. Display the country, year, and life expectancy. --
WITH rank_selected AS (
    SELECT country, year, life_expect, ROW_NUMBER() OVER (PARTITION BY year ORDER BY life_expect DESC) AS row_rank
    FROM world_health_data)
SELECT country, year, life_expect
FROM rank_selected
WHERE row_rank <=5
ORDER BY country, year, row_rank DESC;

-- 2/ Find the countries where life expectancy increased by more than 10% between 2000 and 2020. Show the initial and final life expectancy for those years. --
WITH life_expect_data AS 
    (SELECT country, year, life_expect
    FROM world_health_data
    WHERE year IN (2000,2020)),
    life_expect_diff AS 
    (SELECT country, 
	MAX(CASE WHEN year = 2020 THEN life_expect END) AS life_expect_2020,
        MAX(CASE WHEN year = 2000 THEN life_expect END) AS life_expect_2000
	FROM life_expect_data
    	GROUP BY country)
SELECT country,
		 ((life_expect_2020 - life_expect_2000)*100/life_expect_2000) AS value_difference
FROM life_expect_diff
WHERE  ((life_expect_2020 - life_expect_2000)*100/life_expect_2000) > 0.1;

-- 3/ Rank the countries by health expenditure (health_exp) as a percentage of their average life expectancy for the year 2015. Display the country name, rank, and the calculated percentage. --

WITH health_analysis AS (
    SELECT 
        country,
        health_exp,
        life_expect,
        (health_exp / life_expect * 100) AS health_exp_percentage
    FROM world_health_data
    WHERE year = 2015
)
SELECT 
    country,
    RANK() OVER (ORDER BY health_exp_percentage DESC) AS rank,
    health_exp_percentage
FROM health_analysis
ORDER BY rank;

-- 4/ Find the 5 countries with the highest decrease in under_5_mortality between 1999 and 2019. --

WITH mortality_data AS (
    SELECT 
        country,
        MAX(CASE WHEN year = 1999 THEN under_5_mortality END) AS under_5_mortality_1999,
        MAX(CASE WHEN year = 2019 THEN under_5_mortality END) AS under_5_mortality_2019
    FROM world_health_data
    WHERE year IN (1999, 2019)
    GROUP BY country
)
SELECT 
    country,
    under_5_mortality_1999,
    under_5_mortality_2019,
    (under_5_mortality_1999 - under_5_mortality_2019) AS decrease
FROM mortality_data
ORDER BY decrease DESC
LIMIT 5;

-- 5/ Top 3 Countries with Lowest Neonatal Mortality: For each year, identify the top 3 countries with the lowest neonatal_mortality. Include the year, country, and mortality rate. --

WITH ranked_mortality AS (
    SELECT 
        year,
        country,
        neonatal_mortality,
        ROW_NUMBER() OVER (PARTITION BY YEAR ORDER BY neonatal_mortality ASC) AS rank
    FROM world_health_data
)
SELECT 
    year,
    country,
    neonatal_mortality
FROM ranked_mortality
WHERE rank <= 3
ORDER BY year, rank;

-- 6/ Top 5 Countries by Life Expectancy: Retrieve the top 5 countries with the highest life expectancy in any given year. Display the country, year, and life expectancy. --

WITH life_expectancy_rank AS
	(SELECT country, year, life_expect
	ROW_NUMBER() OVER (PARTITION BY country, ORDER BY life_expect) AS rank
FROM world_health_data
)
SELECT country, year, life_expect
FROM life_expectancy_rank
ORDER BY rank DESC
LIMIT 5;


-- DATABASE IN HOSPITAL: This below one is queries for another database and these SQL queries below are designed to extract specific information from a hospital database. For example, they can reveal the percentage of active/inactive accounts, identify doctors with the most to the fewest skills, calculate annual income, track sales over the past year, or retrieve all details of an appointment for a customer with ID = 1. -- 
-- By utilizing functions like MAX/MIN, TIMESTAMPDIFF, and operations such as subqueries and UNION, these queries manipulate data within a relational database management system to pinpoint the desired information accurately. --

-- 1. This query is written to get customer who have card in the system and show their card by joining card table with customer one together. Left join is used to ensure all cards are shown in case we miss out any customer information in customer table

SELECT cu.id AS customer_id, cu.name, c.card_number
FROM card c 
	LEFT JOIN customer cu ON c.customer_id = cu.id
ORDER BY customer_id;


-- 2. This code is written to get all customers who are staying in Melbourne

SELECT * 
FROM customer
WHERE address LIKE '%Melbourne%';

-- 3. This query is written to show how many percentage of ACTIVE/INACTIVE account

SELECT 'ACTIVE' AS `status`, COUNT(*)*100/(SELECT count(*) 
					FROM account) AS Percentage
FROM account 
WHERE status = 'ACTIVE'

UNION 

SELECT 'INACTIVE' as `status`, count(*)*100/(SELECT COUNT(*) 
					FROM account) AS percentage
FROM account 
WHERE status = 'INACTIVE';

-- 4. The query below will show all Doctor with their skill/department. In this case, the doctor_in_department table is an associative table to represent the relationship between doctors and departments. The first JOIN links the doctor table with the doctor_in_department table based on the doctor's ID, and the second JOIN links the doctor_in_department table with the department table based on the department's ID. From joining these tables together, the query below can retrieve information about doctors and departments including doctor id, doctor name and their departments.

SELECT d.id, d.name, dep.name
FROM doctor d 
     JOIN doctor_in_department dip ON d.id = dip.doctor_id
     JOIN department dep on dep.id = dip.department_id
order by d.id;

-- 5. The query below shows order doctor who has most skills/departments to less. Left join is used to count in case any doctor has zero skills/department. 

SELECT d.id, d.name, COUNT(*) AS total_skills
FROM doctor d 
     LEFT JOIN doctor_in_department dip ON d.id = dip.doctor_id
GROUP BY d.id
ORDER BY total_skills desc;

-- 6. The query below shows departments does not have doctor by first counting if doctor is null or not. If it's null, then return null otherwise count it as 1. At the end, it only appear as the result if department has total_doctor = 0
 
SELECT dep.id, dep.name, COUNT(IF(doctor_id is null, null, 1)) AS total_doctor
FROM department dep
	LEFT JOIN doctor_in_department dip ON dep.id = dip.department_id
GROUP BY dep.id
HAVING total_doctor = 0;

-- 7. The query below shows the result of which departments has most doctor and how many doctors they have. Which one has the least and how many by using union to get both different queries together,subquery and max/min.

SELECT dep.id, dep.name, COUNT(IF(doctor_id is null, null, 1)) AS total_doc
FROM department dep
	LEFT JOIN doctor_in_department dip ON dep.id = dip.department_id
GROUP BY dep.id 
HAVING  total_doc = (SELECT max(total_doc) 
FROM (select dep.id, dep.name, COUNT(IF(doctor_id is null, null, 1)) AS total_doc
FROM department dep
	LEFT JOIN doctor_in_department dip ON dep.id = dip.department_id
GROUP BY dep.id) AS doc_count)

UNION 

SELECT dep.id, dep.name, COUNT(IF(doctor_id is null, null, 1)) AS total_doc
FROM department dep
	LEFT JOIN doctor_in_department dip ON dep.id = dip.department_id
GROUP BY dep.id 
HAVING total_doc = (SELECT min(total_doc) 
FROM (SELECT dep.id, dep.name, COUNT(IF(doctor_id is null, null, 1)) AS total_doc
FROM department dep
	LEFT JOIN doctor_in_department dip ON dep.id = dip.department_id
GROUP BY dep.id) AS doc_count);

-- 8. This below query is to get total income each year by using YEAR to get the year (yyyy) value on date_time (containing dd/mm/yyyy) from booking and it's only shown if the status confirm the transaction is paid.

SELECT YEAR(date_time), sum(price) 
FROM booking
WHERE status = 'PAID'
GROUP BY YEAR(date_time);

-- 9. The query below is written to find out which department has the biggest average imcome for every appointment all the time. It uses avg(price) to get the average income and subquery using select max(average_price) to get the biggest average income.

SELECT department_id, avg(price) AS average_price
FROM booking
GROUP BY department_id
HAVING average_price= (SELECT max(average_price)
						FROM (SELECT department_id, avg(price) AS average_price
								FROM booking
								GROUP BY department_id) AS temp_table);
                                
-- 10. This query below shows the total sell and use TIMESTAMPDIFF and choose MONTH between 0 and 12 to show the sell in the last 12 months.

SELECT sum(price)
FROM booking 
where status = 'PAID'  AND TIMESTAMPDIFF(MONTH, date_time, now()) > 0 AND TIMESTAMPDIFF(MONTH, date_time, now()) <12;


-- 11. The below query reveals the total appointment that each doctor take part in by counting total appointment of each doctor where status = 'DONE'.

SELECT d.id, d.name, COUNT(*) AS total_appointment
FROM appointment a
	JOIN doctor d ON d.id = a.doctor_id
WHERE status = 'DONE'
GROUP BY d.id ;

-- 12. The below query shows all information of an appoinment of a customer who has customer ID = 1

SELECT * 
FROM appointment
WHERE customer_id = 1; 

-- 13. The below query indicates which card never pay by showing card id and card number. It then count the total payment of each card, if payment_time is null, it returns null, otherwise count it as 1 time for each payment. In order to return which card never pay we then put payment_time = 0.

SELECT c.id, c.card_number, COUNT(IF(p.id is null, null, 1)) AS payment_time
FROM card c
	LEFT JOIN payment p ON c.id = p.card_id
GROUP BY c.id
HAVING payment_time = 0;

-- 14. The below one mentions about money paid of each cards.
select c.card_number, sum(price) as total_payment
from payment p 
	join card c on p.card_id = c.id
	join booking b on b.id = p.booking_id
group by c.id;

-- 15. The last query shows which dotor cannot use their skill. It shows doctor ID, doctor name and count their total appointment by mentioning that if appointment id is null, then returns the result of null, otherwise return it as 1. It then left join doctor table with booking to even get doctors who do not have booking, then left join booking table with appointment one together to get the information from these ones. In order to get doctor who cannot utilize their skills, we will put "having total_appointment = 0".

SELECT d.id, d.name, COUNT(IF(a.id is null, null, 1)) AS total_appointment
FROM doctor d 
	LEFT JOIN booking b ON d.id = b.doctor_id
	LEFT JOIN appointment a ON b.id = a.booking_id and a.status = 'DONE'
GROUP BY d.id
HAVING total_appointment = 0;

