/* --------------------
   Case Study #1 - Danny's Diner
   --------------------*/

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m1.price) AS total_amt_spent
	FROM sales AS s
	LEFT JOIN menu AS m1
	ON s.product_id = m1.product_id
GROUP BY 1
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS total_visit_days
	FROM sales
GROUP BY 1
ORDER BY 1;

-- 3. What was the first item from the menu purchased by each customer?
WITH orders AS
				(
				SELECT s.customer_id, m1.product_name, s.order_date, 
				RANK () OVER (PARTITION BY customer_id ORDER BY order_date) as order_rank
					FROM sales AS s
					JOIN menu AS m1
				ON s.product_id = m1.product_id)
				
SELECT customer_id, order_date, product_name
FROM orders
WHERE order_rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m1.product_name, COUNT(s.product_id) AS purchase_count
	FROM sales s
	LEFT JOIN menu m1
	ON s.product_id = m1.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH purchase_count AS
				(
				SELECT s.customer_id, m1.product_name, COUNT(s.product_id),
				RANK () OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) as purchase_rank
					FROM sales AS s
					JOIN menu AS m1
				ON s.product_id = m1.product_id
				GROUP BY 1, 2
				)
				
SELECT customer_id, product_name
FROM purchase_count
WHERE purchase_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member
WITH m2_purchase AS (
					 SELECT s.customer_id, s.order_date, m2.join_date, m1.product_name, 
	   				 RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS first_m2_purchase
						FROM menu AS m1
						LEFT JOIN sales AS s
						ON m1.product_id = s.product_id
						LEFT JOIN members AS m2
						ON s.customer_id = m2.customer_id
					 WHERE s.order_date >= m2.join_date
					 GROUP BY 1, 2, 3, 4
					)
SELECT customer_id, product_name, join_date, order_date
	FROM m2_purchase
WHERE first_m2_purchase = 1
ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?
WITH customer_purchase AS (
						   SELECT DISTINCT m1.product_name, s.customer_id, m2.join_date, s.order_date,
						   RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) ranking
                           		FROM sales s
								LEFT JOIN menu m1
								ON s.product_id = m1.product_id
								LEFT JOIN members m2
								ON s.customer_id = m2.customer_id
						   WHERE order_date < join_date
						  )
						  SELECT customer_id, product_name, order_date, join_date, ranking
	FROM customer_purchase
WHERE ranking = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) AS total_items, SUM(m1.price) AS total_amt_spent
	FROM sales AS s
	INNER JOIN members AS m2
	ON s.customer_id = m2.customer_id
	INNER JOIN menu AS m1
	ON  s.product_id = m1.product_id
WHERE s.order_date < m2.join_date
GROUP BY 1
ORDER BY 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, SUM (CASE WHEN m1.product_id = 2 OR m1.product_id = 3 THEN m1.price * 10 
						   ELSE m1.price * 20 
						   END) AS points
	FROM sales AS s
	LEFT JOIN menu AS m1
	ON s.product_id = m1.product_id
GROUP BY 1
ORDER BY 1, 2;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, SUM (CASE WHEN m1.product_id = 1 OR s.order_date BETWEEN m2.join_date AND m2.join_date + INTERVAL '1 week' THEN m1.price * 20 
						   ELSE price * 10 
						   END) AS m2_points
	FROM sales AS s
	LEFT JOIN menu AS m1
	ON s.product_id = m1.product_id
	LEFT JOIN members AS m2
	ON s.customer_id = m2.customer_id
WHERE m2.join_date IS NOT NULL AND s.order_date <= '2021-01-31'
GROUP BY 1
ORDER BY 1, 2;
