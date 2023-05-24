--	ZOMATO SQL PROJECT  --

--CREATED TABLES goldusers_signup, users, sales, product
--and INSERTED VALUES INTO these tables

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


SELECT * FROM product;
SELECT * FROM goldusers_signup;
SELECT * FROM sales;
SELECT * FROM users;

--Q1. What is the total amount each customer has spend on Zomato

SELECT s.userid,
	sum(p.price) total_amount 
FROM sales s
JOIN product p 
	ON s.product_id = p.product_id
GROUP BY s.userid

--Q2. How many days each customer has visited Zomato?

SELECT userid,
	COUNT(DISTINCT created_date) total_visits 
FROM sales
GROUP BY userid

--Q3. What was the first product bought by the customer?

SELECT * FROM (SELECT userid, 
	created_date,
	product_id, 
	RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk
FROM sales) TEMP_TABLE
WHERE rnk = 1

--Q4. What is the most purchased item and how many times was it bought by all the customers?

SELECT userid, COUNT(product_id) cnt from sales WHERE product_id =
	(SELECT TOP 1 product_id
	FROM sales
	GROUP BY product_id
	ORDER BY COUNT(product_id) DESC)
GROUP BY userid


--to find the most purchased product and the total count of it's 
--purchase we can use TOP and COUNT as shown below

SELECT TOP 1 product_id, COUNT(product_id) Max_Purchase
	FROM sales
	GROUP BY product_id
	ORDER BY COUNT(product_id) DESC

--Q5. Which item was the most favourite item for each customers

--we should find the most purchased item by each customer

SELECT * FROM 
(SELECT *, RANK() Over(partition by userid order by max_purchased_item desc) rnk from 
(SELECT userid, 
	product_id, 
	count(product_id) max_purchased_item
	FROM sales
group by userid, product_id) a) b
WHERE rnk = 1

--Q6. Which item was purchased first after becoming a golden member?

select * from
	(select *, rank() over(partition by userid order by created_date) rnk from 
		(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s
		join goldusers_signup g on g.userid = s.userid
		where s.created_date >= g.gold_signup_date) a) b
where rnk = 1

--Q7. Which item was purchased just before becoming a golden member?

select * from
	(select *, rank() over(partition by userid order by created_date desc) rnk from 
		(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s
		join goldusers_signup g on g.userid = s.userid
		where s.created_date <= g.gold_signup_date) a) b
where rnk = 1

--Q8. What is the total number of orders and amount spent by 
--	  the customers before becoming a golden member?

SELECT s.userid, 
	COUNT(created_date) total_purchases, 
	SUM(p.price) total_amt_spent FROM sales s
	join goldusers_signup g ON g.userid = s.userid
	join product p ON s.product_id = p.product_id 
WHERE created_date <= gold_signup_date
GROUP BY s.userid

/* 
Q9. Buying each product generates different Zomato points (which can be used for cashback during next purchase)
	(₹5 for 2 Zomato points) and each products has different purchase points then calculate the points collected
	by each customer and the the product which gave max points. 
	Here, P1 for ₹5 = 1 point, P2 for ₹10 = 5 point, P3 for ₹5 = 1 point 
*/

-- part 1. calculating the total cashback recieved by each customer

SELECT userid, total_pts_collected*2.5 as total_cashback_earned from 
(SELECT userid, sum(total_points) AS total_pts_collected from
(SELECT b.*, total_amt/points as total_points FROM
(SELECT a.*, 
	CASE WHEN product_id = 1 THEN 5
	WHEN product_id = 2 THEN 2
	WHEN product_id = 3 THEN 5
	ELSE 0
	END AS points
FROM
(SELECT s.userid, s.product_id, SUM(price) total_amt FROM sales s
join product p ON s.product_id = p.product_id
GROUP BY userid, s.product_id) a) b) c
GROUP BY userid) d

-- part 2. calculating the product which gave away max. Zomato points

SELECT TOP 1 product_id, sum(total_points) AS total_pts_given FROM
(SELECT b.*, total_amt/points as total_points FROM
(SELECT a.*, 
	CASE WHEN product_id = 1 THEN 5
	WHEN product_id = 2 THEN 2
	WHEN product_id = 3 THEN 5
	ELSE 0
	END AS points
FROM
(SELECT s.userid, s.product_id, SUM(price) total_amt FROM sales s
join product p ON s.product_id = p.product_id
GROUP BY userid, s.product_id) a) b) c
GROUP BY product_id
ORDER BY total_pts_given DESC

/*
Q10.	Rank all the transactions for each member whenever they are a Zomato gold member
and for every non-gold member transactions mark the rank as 'NA'
*/

SELECT b.*,
	CASE WHEN ranking = 0 THEN 'NA'
	ELSE ranking
	END AS total_ranking
FROM 
    (SELECT a.*,
		 CAST((CASE
    	WHEN gold_signup_date is NULL THEN 0
    	ELSE RANK() over(partition by userid
    ORDER BY  created_date desc) end) AS varchar) ranking
    FROM (SELECT s.userid, s.created_date, gold_signup_date FROM sales s
		  LEFT JOIN goldusers_signup g ON s.userid = g.userid
		  AND created_date >= gold_signup_date) a) b 