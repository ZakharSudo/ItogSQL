-- БАЗА ДАННЫХ 3 - ВСЕ ЗАДАНИЯ


-- ЗАДАНИЕ 1: Активные клиенты
-- Найти клиентов с >2 бронированиями в разных отелях


WITH CustomerBookings AS (
    SELECT 
        c.ID_customer,
        c.name,
        c.email,
        c.phone,
        b.ID_booking,
        h.name AS hotel_name,
        (b.check_out_date - b.check_in_date) AS stay_duration
    FROM 
        Customer c
    INNER JOIN 
        Booking b ON c.ID_customer = b.ID_customer
    INNER JOIN 
        Room r ON b.ID_room = r.ID_room
    INNER JOIN 
        Hotel h ON r.ID_hotel = h.ID_hotel
),
CustomerStats AS (
    SELECT 
        ID_customer,
        name,
        email,
        phone,
        COUNT(ID_booking) AS total_bookings,
        COUNT(DISTINCT hotel_name) AS distinct_hotels,
        ROUND(AVG(stay_duration), 4) AS avg_stay_duration,
        STRING_AGG(DISTINCT hotel_name, ', ' ORDER BY hotel_name) AS hotel_list
    FROM 
        CustomerBookings
    GROUP BY 
        ID_customer, name, email, phone
)
SELECT 
    name,
    email,
    phone,
    total_bookings,
    hotel_list,
    avg_stay_duration
FROM 
    CustomerStats
WHERE 
    total_bookings > 2
    AND distinct_hotels > 1
ORDER BY 
    total_bookings DESC;


-- ЗАДАНИЕ 2: Клиенты с большими тратами
-- Найти клиентов с >2 бронированиями,
-- >1 отелем и тратами > 500$

SELECT 
    c.ID_customer,
    c.name,
    COUNT(DISTINCT b.ID_booking) AS total_bookings,
    ROUND(SUM(r.price * (b.check_out_date - b.check_in_date)), 2) AS total_spent,
    COUNT(DISTINCT h.ID_hotel) AS unique_hotels
FROM 
    Customer c
INNER JOIN 
    Booking b ON c.ID_customer = b.ID_customer
INNER JOIN 
    Room r ON b.ID_room = r.ID_room
INNER JOIN 
    Hotel h ON r.ID_hotel = h.ID_hotel
GROUP BY 
    c.ID_customer, c.name
HAVING 
    COUNT(DISTINCT b.ID_booking) > 2
    AND COUNT(DISTINCT h.ID_hotel) > 1
    AND SUM(r.price * (b.check_out_date - b.check_in_date)) > 500
ORDER BY 
    total_spent ASC;


-- ЗАДАНИЕ 3: Предпочтения клиентов
-- Категоризация отелей и определение
-- предпочитаемого типа отеля для каждого клиента

WITH HotelCategory AS (
    SELECT 
        h.ID_hotel,
        h.name AS hotel_name,
        AVG(r.price) AS avg_price,
        CASE 
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) BETWEEN 175 AND 300 THEN 'Средний'
            ELSE 'Дорогой'
        END AS hotel_category
    FROM 
        Hotel h
    INNER JOIN 
        Room r ON h.ID_hotel = r.ID_hotel
    GROUP BY 
        h.ID_hotel, h.name
),
CustomerVisits AS (
    SELECT 
        c.ID_customer,
        c.name,
        hc.hotel_name,
        hc.hotel_category
    FROM 
        Customer c
    INNER JOIN 
        Booking b ON c.ID_customer = b.ID_customer
    INNER JOIN 
        Room r ON b.ID_room = r.ID_room
    INNER JOIN 
        HotelCategory hc ON r.ID_hotel = hc.ID_hotel
    GROUP BY 
        c.ID_customer, c.name, hc.hotel_name, hc.hotel_category
),
CustomerCategory AS (
    SELECT 
        ID_customer,
        name,
        STRING_AGG(DISTINCT hotel_name, ', ' ORDER BY hotel_name) AS visited_hotels,
        CASE 
            WHEN MAX(CASE WHEN hotel_category = 'Дорогой' THEN 1 ELSE 0 END) = 1 THEN 'Дорогой'
            WHEN MAX(CASE WHEN hotel_category = 'Средний' THEN 1 ELSE 0 END) = 1 THEN 'Средний'
            ELSE 'Дешевый'
        END AS preferred_hotel_type
    FROM 
        CustomerVisits
    GROUP BY 
        ID_customer, name
)
SELECT 
    ID_customer,
    name,
    preferred_hotel_type,
    visited_hotels
FROM 
    CustomerCategory
ORDER BY 
    CASE preferred_hotel_type
        WHEN 'Дешевый' THEN 1
        WHEN 'Средний' THEN 2
        WHEN 'Дорогой' THEN 3
    END;