DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(200),
    reg_date DATE
);
SELECT * FROM customers;

DROP TABLE IF EXISTS resturent;
CREATE TABLE resturent (
    resturent_id VARCHAR(20) PRIMARY KEY,
    resturent_name VARCHAR(30),
    city VARCHAR(20),
    opening_hours VARCHAR(55)
);
SELECT * FROM resturent;

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    resturent_id VARCHAR(20),
    order_item VARCHAR(100),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(100),
    total_amount INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (resturent_id) REFERENCES resturent(resturent_id)
);
SELECT * FROM orders;

DROP TABLE IF EXISTS riders;
CREATE TABLE riders (
    rider_id VARCHAR(20) PRIMARY KEY,
    rider_name VARCHAR(100),
    sign_up DATE
);
SELECT * FROM riders;

DROP TABLE IF EXISTS delivery;
CREATE TABLE delivery (
    delivery_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    delivery_status VARCHAR(100),
    delivery_time TIME,
    rider_id VARCHAR(20),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);
SELECT * FROM delivery;


SELECT COUNT(*) 
FROM customers 
WHERE customer_id IS NULL OR reg_date IS NULL;

SELECT COUNT(*) 
FROM resturent 
WHERE resturent_name IS NULL OR opening_hours IS NULL OR city IS NULL;

SELECT COUNT(*) 
FROM orders 
WHERE order_item IS NULL 
  OR order_date IS NULL 
  OR order_time IS NULL 
  OR order_status IS NULL 
  OR total_amount IS NULL;

SELECT COUNT(*) 
FROM delivery 
WHERE delivery_id IS NULL 
  OR delivery_time IS NULL 
  OR delivery_status IS NULL;

SELECT COUNT(*) 
FROM riders 
WHERE rider_id IS NULL 
  OR rider_name IS NULL 
  OR sign_up IS NULL;

  
SELECT customer_name, dishes, total_orders
FROM (
    SELECT 
        c.customer_id,
        c.customer_name,
        o.order_item AS dishes,
        COUNT(*) AS total_orders,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
      AND c.customer_name = 'customer1'
    GROUP BY c.customer_id, c.customer_name, o.order_item
) AS ti
WHERE rank <= 5;
select current_date-interval '1 Year'


SELECT 
  CASE 
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00-02:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00-04:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00-06:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00-08:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00-10:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00-12:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00-14:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00-16:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00-18:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00-20:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00-22:00'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00-00:00'
    ELSE 'Unknown'
  END AS time_slot,
  COUNT(order_id) AS order_count
FROM orders 
GROUP BY time_slot
ORDER BY order_count DESC;

SELECT 
    o.customer_id, 
    AVG(o.total_amount) AS average_amount,
    COUNT(o.order_id) AS total_orders
FROM orders AS o
JOIN customers AS c
    ON c.customer_id = o.customer_id
GROUP BY o.customer_id
HAVING COUNT(o.order_id) < 7500;


SELECT 
    o.customer_id, 
    sum(o.total_amount) AS total_spend,
    COUNT(o.order_id) AS total_orders
FROM orders AS o
JOIN customers AS c
    ON c.customer_id = o.customer_id
GROUP BY o.customer_id
having sum(o.total_amount)<100000;


select * from order o left join resturent as r
on r.resturent_id=o.resturent_id
left join deliveries as d on d.order_id=o.order_id
where d.delivery_id is null;


SELECT 
    r.city,
    r.resturent_name,
    SUM(o.total_amount) AS revenue,
	rank() over(order by sum(o.total_amount)desc)as rank
FROM orders AS o
JOIN resturent AS r ON r.resturent_id = o.resturent_id
GROUP BY r.city, r.resturent_name
ORDER BY revenue DESC;


SELECT  
    r.city, 
    o.order_item AS dish,
    COUNT(o.order_id) AS total_orders
FROM orders AS o
JOIN resturent AS r ON r.resturent_id = o.resturent_id
GROUP BY r.city, o.order_item
ORDER BY total_orders DESC;

SELECT DISTINCT customer_id
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2020
  AND customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2021
);

SELECT o.resturent_id, COUNT(o.order_id) AS total_orders
FROM orders AS o
LEFT JOIN delivery AS d ON o.order_id = d.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2024
GROUP BY o.resturent_id;

WITH cancel_ratio_24 AS (
    SELECT 
        o.resturent_id, 
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders AS o
    LEFT JOIN delivery AS d ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
    GROUP BY o.resturent_id
)

SELECT 
    resturent_id, 
    total_orders, 
    not_delivered,
    ROUND((not_delivered::numeric / total_orders) * 100, 2) AS cancel_ratio
FROM cancel_ratio_24;


SELECT
    d.rider_id,
    o.order_time,
    o.order_id,
    o.order_time - d.delivery_time AS time_diff,
    EXTRACT(
        EPOCH FROM (
            (d.delivery_time + 
                CASE 
                    WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
                    ELSE INTERVAL '0 day'
                END
            ) 
            - o.order_time
        )
    ) AS time_diffe
FROM orders AS o
JOIN delivery AS d
    ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';


SELECT 
    o.resturent_id,
    TO_CHAR(o.order_date, 'MM-YY') AS month
FROM orders AS o
JOIN delivery AS d
    ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
group by 1,2
order by 1,2;


SELECT 
    customer_id,
    SUM(total_amount) AS total_spend,
    CASE 
        WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
        ELSE 'Silver'
    END AS cw_category
FROM orders
GROUP BY customer_id
ORDER BY total_spend DESC;



SELECT 
    d.rider_id,
    TO_CHAR(o.order_date, 'MM-YY') AS month,
    SUM(o.total_amount) * 0.08 AS rider_earning
FROM orders AS o
JOIN delivery AS d ON o.order_id = d.order_id
GROUP BY d.rider_id, TO_CHAR(o.order_date, 'MM-YY')
ORDER BY d.rider_id, month;

SELECT 
    rider_id,
    stars,
    COUNT(*) AS total_stars
FROM (
    SELECT 
        d.rider_id,
        EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
            CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
        )) / 60 AS delivery_took_time,
        CASE 
            WHEN EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
                CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
            )) / 60 < 15 THEN '5 star'
            WHEN EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
                CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
            )) / 60 BETWEEN 15 AND 20 THEN '4 star'
            ELSE '3 star'
        END AS stars
    FROM orders AS o
    JOIN delivery AS d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
) AS t1
GROUP BY rider_id, stars
ORDER BY rider_id, total_stars DESC;

SELECT 
    r.resturent_name,
    o.order_id,
    TO_CHAR(o.order_date, 'Day') AS day_name,
    COUNT(o.order_id) AS total_orders,
    o.order_date
FROM orders AS o
JOIN resturent AS r ON o.resturent_id = r.resturent_id
GROUP BY r.resturent_name, o.order_id, TO_CHAR(o.order_date, 'Day'), o.order_date
ORDER BY r.resturent_name, total_orders DESC;
