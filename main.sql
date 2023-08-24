--: Using a CTE, find out the total number of films rented for each rating (like 'PG', 'G', etc.) in the year 2005. 
--List the ratings that had more than 50 rentals.

WITH CTE_TOTAL_RENTALS_RATING AS
(
SELECT
    se_film.rating,
    COUNT(se_rental.rental_id) AS total_rentals
FROM public.rental AS se_rental
INNER JOIN public.inventory AS se_inventory
ON se_rental.inventory_id=se_inventory.inventory_id
INNER JOIN public.film AS se_film
ON se_inventory.film_id=se_film.film_id
WHERE EXTRACT(YEAR FROM se_rental.rental_date)=2005
GROUP BY 
    se_film.rating
HAVING COUNT(se_rental.rental_id)>50
)

--: Identify the categories of films that have an average rental duration greater than 5 days. 
-- Only consider films rated 'PG' or 'G'.

SELECT
    se_category.name,
    AVG(se_film.rental_duration) AS avg_rental_duration
FROM public.film AS se_film
INNER JOIN public.film_category AS se_film_category
ON se_film.film_id=se_film_category.film_id
INNER JOIN public.category AS se_category
ON se_film_category.category_id=se_category.category_id
WHERE se_film.rating='PG' OR se_film.rating='G'
GROUP BY 
    se_category.name
HAVING AVG(se_film.rental_duration)>5

--: Determine the total rental amount collected from each customer. 
--List only those customers who have spent more than $100 in total.

SELECT
    se_payment.customer_id,
    SUM(COALESCE(se_payment.amount,0)) AS total_amount
FROM public.payment AS se_payment
GROUP BY 
    se_payment.customer_id
HAVING SUM(COALESCE(se_payment.amount,0))>100

--: Create a temporary table containing the names and email addresses
-- of customers who have rented more than 10 films.

CREATE TEMPORARY TABLE customer_more_than_10 AS
(
SELECT
    CONCAT(se_customer.first_name,' ',se_customer.last_name) AS full_name,
    se_customer.email
FROM public.rental AS se_rental
INNER JOIN public.customer AS se_customer
ON se_rental.customer_id=se_customer.customer_id
GROUP BY 
    CONCAT(se_customer.first_name,' ',se_customer.last_name),
    se_customer.email
HAVING COUNT(DISTINCT se_rental.rental_id)>10
);

-- : From the temporary table created in Task 3.1, 
-- identify customers who have a Gmail email address (i.e., their email ends with '@gmail.com').

SELECT 
    customer_more_than_10.full_name
FROM customer_more_than_10
WHERE customer_more_than_10.email LIKE '%@gmail.com'

--Start by creating a CTE that finds the total number of films rented for each category.

WITH CTE_TOTAL_RENTALS_CATEGORY AS
(
SELECT  
	se_category.name AS category_name,
	COALESCE(COUNT(DISTINCT se_rental.rental_id),0) AS total_rentals	
FROM public.category AS se_category
LEFT OUTER JOIN public.film_category AS se_film_category
	ON se_film_category.category_id = se_category.category_id
LEFT OUTER JOIN public.inventory AS se_inventory 
	ON se_film_category.film_id = se_inventory.film_id
LEFT OUTER JOIN public.rental AS se_rental 
	ON se_inventory.inventory_id = se_rental.inventory_id
GROUP BY 
	se_category.name
)

--Create a temporary table from this CTE.

CREATE TEMPORARY TABLE TOTAL_RENTALS_CATEGORY AS

WITH CTE_TOTAL_RENTALS_CATEGORY AS
(
SELECT  
	se_category.name AS category_name,
	COALESCE(COUNT(DISTINCT se_rental.rental_id),0) AS total_rentals	
FROM public.category AS se_category
LEFT OUTER JOIN public.film_category AS se_film_category
	ON se_film_category.category_id = se_category.category_id
LEFT OUTER JOIN public.inventory AS se_inventory 
	ON se_film_category.film_id = se_inventory.film_id
LEFT OUTER JOIN public.rental AS se_rental 
	ON se_inventory.inventory_id = se_rental.inventory_id
GROUP BY 
	se_category.name
)

--Using the temporary table, list the top 5 categories with the highest number of rentals. 
--Ensure the results are in descending order.

SELECT 
    TOTAL_RENTALS_CATEGORY.name AS TOP_5
FROM TOTAL_RENTALS_CATEGORY
ORDER BY 
    TOTAL_RENTALS_CATEGORY.total_rentals DESC
LIMIT 5

--Identify films that have never been rented out. Use a combination of CTE and LEFT JOIN for this task.

WITH CTE_FILMS AS 
(
SELECT
	se_film.film_id,
	se_film.title,
	se_rental.rental_id
FROM public.film AS se_film
LEFT OUTER JOIN public.inventory AS se_inventory
ON se_inventory.film_id=se_film.film_id
LEFT OUTER JOIN public.rental AS se_rental
ON se_inventory.inventory_id=se_rental.inventory_id
)

SELECT
	CTE_FILMS.title
FROM CTE_FILMS
WHERE CTE_FILMS.rental_id is NULL

--(INNER JOIN): Find the names of customers who rented films with a replacement cost greater than $20 
--and which belong to the 'Action' or 'Comedy' categories.

SELECT 
    DISTINCT se_customer.customer_id,
    se_customer.first_name,
    se_customer.last_name
FROM public.customer AS se_customer
INNER JOIN public.rental AS se_rental
ON se_customer.customer_id=se_rental.customer_id
INNER JOIN public.inventory AS se_inventory
ON se_rental.inventory_id=se_inventory.inventory_id
INNER JOIN public.film AS se_film
ON se_inventory.film_id=se_film.film_id
INNER JOIN public.film_category AS se_film_category
ON se_film.film_id=se_film_category.film_id
INNER JOIN public.category AS se_category
ON se_film_category.category_id=se_category.category_id
WHERE se_film.replacement_cost>20
AND (se_category.name='Action' OR se_category.name='Comedy')

--(LEFT JOIN): List all actors who haven't appeared in a film with a rating of 'R'.

WITH CTE_ACTORS_R AS
(
SELECT
	DISTINCT se_actor.actor_id
	FROM public.actor AS se_actor
LEFT OUTER JOIN public.film_actor AS se_film_actor
ON se_actor.actor_id=se_film_actor.actor_id
LEFT OUTER JOIN public.film AS se_film
ON se_film_actor.film_id=se_film.film_id
WHERE se_film.rating='R'
)

SELECT
	se_actor.first_name,
	se_actor.last_name
FROM public.actor AS se_actor
LEFT OUTER JOIN CTE_ACTORS_R
ON se_actor.actor_id=CTE_ACTORS_R.actor_id
WHERE CTE_ACTORS_R.actor_id IS NULL

--(Combination of INNER JOIN and LEFT JOIN):
-- Identify customers who have never rented a film from the 'Horror' category.

WITH CTE_CUSTOMERS_HORROR_RENTALS AS
(
SELECT 
    DISTINCT se_customer.customer_id,
    se_customer.first_name,
    se_customer.last_name
FROM public.customer AS se_customer
INNER JOIN public.rental AS se_rental
ON se_customer.customer_id=se_rental.customer_id
INNER JOIN public.inventory AS se_inventory
ON se_rental.inventory_id=se_inventory.inventory_id
INNER JOIN public.film AS se_film
ON se_inventory.film_id=se_film.film_id
INNER JOIN public.film_category AS se_film_category
ON se_film.film_id=se_film_category.film_id
INNER JOIN public.category AS se_category
ON se_film_category.category_id=se_category.category_id
WHERE se_category.name='Horror'
)

SELECT 
    se_customer.first_name,
    se_customer.last_name
FROM public.customer AS se_customer
LEFT OUTER JOIN CTE_CUSTOMERS_HORROR_RENTALS
ON se_customer.customer_id=CTE_CUSTOMERS_HORROR_RENTALS.customer_id
WHERE CTE_CUSTOMERS_HORROR_RENTALS.customer_id IS NULL

-- Find the names and email addresses of customers who rented films directed by a specific actor 
-- (let's say, for the sake of this task, that the actor's first name is 'Nick' and last name is 'Wahlberg', 
-- although this might not match actual data in the DVD Rental database).

SELECT 
    DISTINCT se_customer.customer_id,
    CONCAT(se_customer.first_name,' ',se_customer.last_name) AS full_name,
    se_customer.email
FROM public.customer AS se_customer
INNER JOIN public.rental AS se_rental
ON se_customer.customer_id=se_rental.customer_id
INNER JOIN public.inventory AS se_inventory
ON se_rental.inventory_id=se_inventory.inventory_id
INNER JOIN public.film AS se_film
ON se_inventory.film_id=se_film.film_id
INNER JOIN public.film_actor AS se_film_actor
ON se_film.film_id=se_film_actor.film_id
INNER JOIN public.actor AS se_actor
ON se_film_actor.actor_id=se_actor.actor_id
WHERE se_actor.first_name='Nick'
AND se_actor.last_name='Wahlberg'