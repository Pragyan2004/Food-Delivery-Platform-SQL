﻿# Food-Delivery-Platform-SQL

This project contains **SQL scripts** to perform data modeling, cleaning, and analysis for a Food Delivery Platform.  
The database includes customers, restaurants, riders, orders, and delivery data.


#  Project Structure

- `customers` table
- `resturent` table
- `orders` table
- `riders` table
- `delivery` table


#  Table Creation Scripts

    DROP TABLE IF EXISTS customers;
    CREATE TABLE customers (
        customer_id VARCHAR(20) PRIMARY KEY,
        customer_name VARCHAR(200),
        reg_date DATE
    );
    
    DROP TABLE IF EXISTS resturent;
    CREATE TABLE resturent (
        resturent_id VARCHAR(20) PRIMARY KEY,
        resturent_name VARCHAR(30),
        city VARCHAR(20),
        opening_hours VARCHAR(55)
    );
    
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
    
    DROP TABLE IF EXISTS riders;
    CREATE TABLE riders (
        rider_id VARCHAR(20) PRIMARY KEY,
        rider_name VARCHAR(100),
        sign_up DATE
    );
    
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

# Data Quality Checks

    SELECT COUNT(*) FROM customers WHERE customer_id IS NULL OR reg_date IS NULL;
    SELECT COUNT(*) FROM resturent WHERE resturent_name IS NULL OR opening_hours IS NULL OR city IS NULL;
    SELECT COUNT(*) FROM orders WHERE order_item IS NULL OR order_date IS NULL OR order_time IS NULL OR order_status IS NULL OR total_amount IS NULL;
    SELECT COUNT(*) FROM delivery WHERE delivery_id IS NULL OR delivery_time IS NULL OR delivery_status IS NULL;
    SELECT COUNT(*) FROM riders WHERE rider_id IS NULL OR rider_name IS NULL OR sign_up IS NULL;
    
# Data Analysis Queries

# Top 5 Dishes per Customer

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

# Orders by Time Slot
    
    SELECT 
      CASE 
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00-02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00-04:00'
        ...
        ELSE 'Unknown'
      END AS time_slot,
      COUNT(order_id) AS order_count
    FROM orders 
    GROUP BY time_slot
    ORDER BY order_count DESC;

# Average Spend and Total Orders per Customer

    SELECT 
        o.customer_id, 
        AVG(o.total_amount) AS average_amount,
        COUNT(o.order_id) AS total_orders
    FROM orders AS o
    JOIN customers AS c ON c.customer_id = o.customer_id
    GROUP BY o.customer_id
    HAVING COUNT(o.order_id) < 7500;

# Total Spend Filtered (< 100K)
    
    SELECT 
        o.customer_id, 
        SUM(o.total_amount) AS total_spend,
        COUNT(o.order_id) AS total_orders
    FROM orders AS o
    JOIN customers AS c ON c.customer_id = o.customer_id
    GROUP BY o.customer_id
    HAVING SUM(o.total_amount) < 100000;
    
# Orders without Delivery (NULL delivery_id)
    
    SELECT * 
    FROM orders o 
    LEFT JOIN resturent r ON r.resturent_id = o.resturent_id
    LEFT JOIN delivery d ON d.order_id = o.order_id
    WHERE d.delivery_id IS NULL;
    # Restaurant Revenue Rankings
    
    SELECT 
        r.city,
        r.resturent_name,
        SUM(o.total_amount) AS revenue,
        RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS rank
    FROM orders o
    JOIN resturent r ON r.resturent_id = o.resturent_id
    GROUP BY r.city, r.resturent_name
    ORDER BY revenue DESC;
    
# Dish Popularity per City

    SELECT  
        r.city, 
        o.order_item AS dish,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN resturent r ON r.resturent_id = o.resturent_id
    GROUP BY r.city, o.order_item
    ORDER BY total_orders DESC;

# Lost Customers (2020 active, but not 2021)

    SELECT DISTINCT customer_id
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2020
      AND customer_id NOT IN (
        SELECT DISTINCT customer_id
        FROM orders
        WHERE EXTRACT(YEAR FROM order_date) = 2021
    );
# Restaurant Orders (2024)

    SELECT o.resturent_id, COUNT(o.order_id) AS total_orders
    FROM orders o
    LEFT JOIN delivery d ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
    GROUP BY o.resturent_id;


# Cancel Ratio
    
    WITH cancel_ratio_24 AS (
        SELECT 
            o.resturent_id, 
            COUNT(o.order_id) AS total_orders,
            COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
        FROM orders o
        LEFT JOIN delivery d ON o.order_id = d.order_id
        WHERE EXTRACT(YEAR FROM o.order_date) = 2024
        GROUP BY o.resturent_id
    )
    SELECT 
        resturent_id, 
        total_orders, 
        not_delivered,
        ROUND((not_delivered::numeric / total_orders) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_24;

# Delivery Time Differences

    SELECT
        d.rider_id,
        o.order_time,
        o.order_id,
        o.order_time - d.delivery_time AS time_diff,
        EXTRACT(
            EPOCH FROM (
                (d.delivery_time + 
                    CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
                ) - o.order_time
            )
        ) AS time_diffe
    FROM orders o
    JOIN delivery d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered';

 # Monthly Delivered Orders by Restaurant

    SELECT 
        o.resturent_id,
        TO_CHAR(o.order_date, 'MM-YY') AS month
    FROM orders o
    JOIN delivery d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY o.resturent_id, TO_CHAR(o.order_date, 'MM-YY')
    ORDER BY o.resturent_id, month;
#  Customer Segmentation
    
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

# Rider Earnings per Month

    SELECT 
        d.rider_id,
        TO_CHAR(o.order_date, 'MM-YY') AS month,
        SUM(o.total_amount) * 0.08 AS rider_earning
    FROM orders o
    JOIN delivery d ON o.order_id = d.order_id
    GROUP BY d.rider_id, TO_CHAR(o.order_date, 'MM-YY')
    ORDER BY d.rider_id, month;

# Rider Ratings
    
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
        FROM orders o
        JOIN delivery d ON o.order_id = d.order_id
        WHERE d.delivery_status = 'Delivered'
    ) t1
    GROUP BY rider_id, stars
    ORDER BY rider_id, total_stars DESC;


#  Orders per Day per Restaurant
    
    SELECT 
        r.resturent_name,
        o.order_id,
        TO_CHAR(o.order_date, 'Day') AS day_name,
        COUNT(o.order_id) AS total_orders,
        o.order_date
    FROM orders o
    JOIN resturent r ON o.resturent_id = r.resturent_id
    GROUP BY r.resturent_name, o.order_id, TO_CHAR(o.order_date, 'Day'), o.order_date
    ORDER BY r.resturent_name, total_orders DESC;

# END Diagram 

![Screenshot 2025-06-02 223752](https://github.com/user-attachments/assets/6080df33-f226-402b-ab13-f5035491bf78)

