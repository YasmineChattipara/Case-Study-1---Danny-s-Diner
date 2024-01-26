---Danny's Diner Case Study 1

--Create table sales, members, menu and insert given values


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
  
  
--What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, SUM(menu.price) AS total_amount
FROM sales
LEFT JOIN members ON members.customer_id = sales.customer_id
LEFT JOIN menu ON menu.product_id = sales.product_id
GROUP BY sales.customer_id;

OUTPUT
customer_id	total_amount
A	76
B	74
C	36
	
--How many days has each customer visited the restaurant?
select customer_id,count(DISTINCT order_date) AS  days from sales group BY customer_id;

OUTPUT
customer_id	days
A	4
B	6
C	2
	
--What was the first item from the menu purchased by each customer?
with RankedSales AS
(select m.product_name as item,
s.customer_id,
Rank() over(partition BY s.customer_id order by s.order_date ASC) AS Rnk,
ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS RN
from menu m 
join sales s ON s.product_id=m.product_id)
SELECT customer_id, 
	   item
from RankedSales 
where Rnk=1 ;

OUTPUT
customer_id	item
A	sushi
A	curry
B	curry
C	ramen
C	ramen

--What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 product_name,
       COUNT(*) AS product_count
FROM sales s 
JOIN menu m ON m.product_id = s.product_id
GROUP BY product_name
ORDER BY product_count DESC ;

OUTPUT
product_name	product_count
ramen	8

-- Which item was the most popular for each customer?
WITH RankedItems AS (
  SELECT
    m.product_name,
    s.customer_id,
    COUNT(*) AS product_count,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
  FROM
    sales s
    JOIN menu m ON m.product_id = s.product_id
  GROUP BY
    m.product_name, s.customer_id
)
SELECT
  product_name,
  customer_id,
  product_count
FROM
  RankedItems
WHERE
  rank = 1
ORDER BY
  customer_id ;

OUTPUT
product_name	customer_id	product_count
ramen	A	3
curry	B	2
ramen	C	3
	
--Which item was purchased first by the customer after they became a member?
WITH RankedPurchases AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_rank
  FROM
    menu m
    JOIN sales s ON s.product_id = m.product_id
    JOIN members ON members.customer_id = s.customer_id
  WHERE
    s.order_date >= members.join_date
)
SELECT
  customer_id,
  product_name
FROM
  RankedPurchases
WHERE
  purchase_rank = 1;


OUTPUT
customer_id	product_name
A	curry
B	sushi
	
--Which item was purchased just before the customer became a member?
WITH RankedPurchases AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_rank
  FROM
    menu m
    JOIN sales s ON s.product_id = m.product_id
    JOIN members ON members.customer_id = s.customer_id
  WHERE
    s.order_date > members.join_date
)
SELECT
  customer_id,
  product_name
FROM
  RankedPurchases
WHERE
  purchase_rank = 1;

OUTPUT
customer_id	product_name
A	ramen
B	sushi
	
--What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,
count(m.product_id) as Total_Items,
SUM(m.price) AS Amount_Spent
FROM menu m
JOIN sales s ON s.product_id = m.product_id
JOIN members ON members.customer_id = s.customer_id
  WHERE
    s.order_date < members.join_date
   group by s.customer_id;

OUTPUT
customer_id	Total_Items	Amount_Spent
A	2	25
B	3	40

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id,
    SUM(CASE 
            WHEN m.product_name LIKE 'sus%'
                THEN m.price * 20  -- Apply 2x points multiplier for sushi
            ELSE
                m.price * 10  -- Regular points for other products
        END) AS points
FROM 
    sales s
    INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY 
    s.customer_id;

OUTPUT
customer_id	points
A	860
B	940
C	360	

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT
	s.customer_id,
	SUM(CASE WHEN m.product_name LIKE 'sus%'
			 THEN m.price * 20
			 WHEN s.order_date > DATEADD(day, 6, members.join_date)
			 THEN m.price * 20
			 ELSE m.price * 10
		END) AS points
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
INNER JOIN members ON s.customer_id = members.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

OUTPUT
customer_id	points
A	860
B	940
