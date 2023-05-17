CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_sales FROM sales s JOIN menu m ON s.product_id=m.product_id GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS num_of_visits FROM sales GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_item_cte AS 
(
	SELECT s.customer_id,s.order_date,m.product_name, 
    DENSE_RANK() OVER(PARTITION BY s.customer_id 
    ORDER BY s.order_date) AS item_order_rank 
    FROM  sales s JOIN menu m ON s.product_id=m.product_id
)
SELECT customer_id ,order_date,product_name FROM first_item_cte WHERE item_order_rank=1 GROUP BY customer_id,product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT COUNT(s.product_id) AS most_purchased , m.product_name FROM sales s JOIN menu m ON s.product_id=m.product_id 
GROUP BY m.product_name ORDER BY most_purchased DESC LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH popular_product_cte AS
(
	SELECT s.customer_id,m.product_name, COUNT(s.product_id) as count_orders,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS popularity_rank
    FROM sales s JOIN menu m ON s.product_id=m.product_id GROUP BY s.customer_id,m.product_name
)
SELECT customer_id,product_name,count_orders FROM popular_product_cte WHERE popularity_rank=1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_purchase_as_member_cte AS
(
	SELECT s.customer_id,s.order_date,mem.join_date,s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS first_purchase_rank
	FROM sales s JOIN members mem ON s.customer_id=mem.customer_id 
	WHERE s.order_date >= mem.join_date
)
SELECT fp.customer_id,fp.order_date,m.product_name 
FROM first_purchase_as_member_cte fp JOIN menu m ON fp.product_id=m.product_id 
WHERE fp.first_purchase_rank=1 GROUP BY fp.customer_id,fp.order_date,m.product_name ORDER BY fp.customer_id;

-- 7. Which item was purchased just before the customer became a member?
WITH last_purchase_before_member_cte AS
(
	SELECT s.customer_id,s.order_date,mem.join_date,s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS last_purchase_rank
	FROM sales s JOIN members mem ON s.customer_id=mem.customer_id 
	WHERE s.order_date < mem.join_date
)
SELECT lp.customer_id,lp.order_date,m.product_name 
FROM last_purchase_before_member_cte lp JOIN menu m ON lp.product_id=m.product_id 
WHERE lp.last_purchase_rank=1 GROUP BY lp.customer_id,lp.order_date,m.product_name ORDER BY lp.customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) AS total_items , SUM(m.price) AS amount_spent 
FROM sales s JOIN menu m ON s.product_id=m.product_id JOIN members mem ON s.customer_id=mem.customer_id 
WHERE s.order_date<mem.join_date GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_cte AS
(
	SELECT *,
    CASE 
		WHEN product_id=1 THEN price*20
        ELSE price*10
	END AS points
    FROM menu
)
SELECT s.customer_id, SUM(pts.points) AS total_points 
FROM sales s JOIN points_cte pts ON s.product_id=pts.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH date_cte AS
(
	SELECT *,
    DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date,
    LAST_DAY("2021-01-31") AS last_date
    FROM members
)
SELECT s.customer_id, 
SUM(CASE 
	WHEN s.product_id=1 THEN price*20
    WHEN s.product_id != 1 AND s.order_date BETWEEN d.join_date AND d.valid_date THEN price*20
    ELSE price *10
END) AS total_points
FROM date_cte d JOIN sales s ON d.customer_id=s.customer_id JOIN menu m ON s.product_id=m.product_id 
WHERE s.order_date <= d.last_date GROUP BY s.customer_id;
