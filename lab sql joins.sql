/* 1) Films per category */
SELECT c.name AS category,
       COUNT(*) AS film_count
FROM category AS c
JOIN film_category AS fc ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY film_count DESC, category;

/* 2) Store location info */
SELECT s.store_id,
       ci.city,
       co.country
FROM store    AS s
JOIN address  AS a   ON a.address_id = s.address_id
JOIN city     AS ci  ON ci.city_id    = a.city_id
JOIN country  AS co  ON co.country_id = ci.country_id
ORDER BY s.store_id;

/* 3) Revenue per store via staff->store */
SELECT s.store_id,
       ROUND(SUM(p.amount), 2) AS revenue_usd
FROM payment AS p
JOIN staff   AS st ON st.staff_id = p.staff_id
JOIN store   AS s  ON s.store_id  = st.store_id
GROUP BY s.store_id
ORDER BY s.store_id;


/* 4) Avg film length per category (minutes) */
SELECT c.name AS category,
       ROUND(AVG(f.length), 2) AS avg_length_min
FROM film AS f
JOIN film_category AS fc ON fc.film_id     = f.film_id
JOIN category      AS c  ON c.category_id  = fc.category_id
GROUP BY c.category_id, c.name
ORDER BY avg_length_min DESC, category;

/* Bonus A: longest avg running time (tie-aware) */
WITH cat_avg AS (
  SELECT fc.category_id, AVG(f.length) AS avg_len
  FROM film f
  JOIN film_category fc ON fc.film_id = f.film_id
  GROUP BY fc.category_id
),
max_avg AS (
  SELECT MAX(avg_len) AS max_len FROM cat_avg
)
SELECT c.name AS category, ROUND(ca.avg_len, 2) AS avg_length_min
FROM cat_avg ca
JOIN max_avg m ON ca.avg_len = m.max_len
JOIN category c ON c.category_id = ca.category_id;


/* Bonus B: top 10 most rented films */
SELECT f.film_id,
       f.title,
       COUNT(*) AS rental_count
FROM rental    AS r
JOIN inventory AS i ON i.inventory_id = r.inventory_id
JOIN film      AS f ON f.film_id      = i.film_id
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC, f.title
LIMIT 10;


/* Bonus C: availability now = at least one copy not out on rental */
SELECT CASE WHEN COUNT(*) > 0 THEN 'Yes' ELSE 'No' END AS can_be_rented_now
FROM inventory AS i
JOIN film      AS f ON f.film_id = i.film_id
LEFT JOIN rental AS r
  ON r.inventory_id = i.inventory_id
 AND r.return_date IS NULL      -- still out
WHERE f.title = 'Academy Dinosaur'
  AND i.store_id = 1
  AND r.rental_id IS NULL;      -- means this copy is not currently rented


/* Bonus D: title availability using CASE + IFNULL */
SELECT f.title,
       CASE WHEN IFNULL(inv.copies, 0) = 0
            THEN 'NOT available'
            ELSE 'Available'
       END AS availability
FROM film AS f
LEFT JOIN (
  SELECT film_id, COUNT(*) AS copies
  FROM inventory
  GROUP BY film_id
) AS inv ON inv.film_id = f.film_id
ORDER BY f.title;

-- Optional check:
SELECT COUNT(*) AS not_in_inventory_titles
FROM (
  SELECT f.title,
         CASE WHEN IFNULL(inv.copies, 0) = 0 THEN 'NOT available' ELSE 'Available' END AS availability
  FROM film AS f
  LEFT JOIN (
    SELECT film_id, COUNT(*) AS copies
    FROM inventory
    GROUP BY film_id
  ) AS inv ON inv.film_id = f.film_id
) q
WHERE q.availability = 'NOT available';

