CREATE DATABASE Eight_week_SQL_Challenge;


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

/*
CASE STUDY 1 - Danny's Diner
*/

select * from members
select * from menu
select * from sales

/*
1. What is the total amount each customer spent at the restaurant?
*/
select customer_id, 
	sum(price) amount_spent
from sales s
	join menu m on s.product_id = m.product_id
group by customer_id

/*
2. How many days has each customer visited the restaurant?
*/
select customer_id, count(order_date) total_visit from sales
group by customer_id

/*
3. What was the first item from the menu purchased by each customer?
*/
select ordered.* from 
(select order_date, 
	row_number() over(partition by customer_id order by order_date) rn,
	customer_id, 
	product_name 
from sales s
join menu mn on s.product_id = mn.product_id) ordered
where rn = 1

/*
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
*/
select top 1 product_name, 
	count(order_date) total_count_of_purchase from sales s
join menu mn on s.product_id = mn.product_id
group by product_name
order by total_count_of_purchase desc

/*
5. Which item was the most popular for each customer?
*/
select favourite.* from
(select customer_id, 
	product_name, 
	count(order_date) total_count, 
	rank() over(partition by customer_id order by count(order_date) desc) rnk
from sales s
join menu mn on s.product_id = mn.product_id
group by customer_id, product_name) favourite
where rnk = 1

/*
6. Which item was purchased first by the customer after they became a member?
*/
select first_order.* from
(select s.customer_id, product_name,
	row_number() over(partition by s.customer_id order by s.customer_id) rnk
from sales s
join members mr on s.customer_id = mr.customer_id
join menu mn on s.product_id = mn.product_id
where order_date >= join_date) first_order
where rnk = 1

/*
7. Which item was purchased just before the customer became a member?
*/
select order_before_membership.* from
(select s.customer_id, order_date, join_date, product_name,
	rank() over(partition by s.customer_id order by order_date desc) rnk
from sales s
join members mr on s.customer_id = mr.customer_id
join menu mn on s.product_id = mn.product_id
where order_date < join_date) order_before_membership
where rnk = 1

/*
8. What is the total items and amount spent for each member before they became a member?
*/
select s.customer_id, count(order_date) total_items_purchased, sum(price) total_amt_spent
from sales s
join members mr on s.customer_id = mr.customer_id
join menu mn on s.product_id = mn.product_id
where order_date < join_date
group by s.customer_id

/*
9. If each $1 spent equates to 10 points and sushi has a 
	2x points multiplier - how many points would each customer have?
*/
WITH price_points_cte AS
(
SELECT *, 
		CASE WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10 END AS points
FROM menu
)
SELECT s.customer_id, 
  SUM(p.points) AS total_points
FROM price_points_cte AS p
	JOIN sales AS s ON p.product_id = s.product_id
GROUP BY s.customer_id

/*
10. In the first week after a customer joins the program (including their join date) they earn 2x points
	on all items, not just sushi - how many points do customer A and B have at the end of January?
*/
WITH dates_cte AS 
(
SELECT *, 
    DATEADD(DAY, 6, join_date) AS valid_date, 
	EOMONTH('2021-01-31') AS last_date
FROM members AS m
)
SELECT d.customer_id, 
  s.order_date, d.join_date, 
  d.valid_date, d.last_date, 
  m.product_name, m.price,
	SUM(
		CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
		WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
		ELSE 10 * m.price END) AS points
FROM dates_cte AS d
	JOIN sales AS s ON d.customer_id = s.customer_id
	JOIN menu AS m ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date,
	d.join_date, d.valid_date, d.last_date,
	m.product_name, m.price














