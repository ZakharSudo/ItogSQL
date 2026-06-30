-- БАЗА ДАННЫХ 2 - ВСЕ ЗАДАНИЯ

-- ЗАДАНИЕ 1: Лучший автомобиль в каждом классе
-- Определить автомобили с наименьшей средней позицией
-- в гонках для каждого класса

WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM 
        Cars c
    INNER JOIN 
        Results r ON c.name = r.car
    GROUP BY 
        c.name, c.class
),
RankedCars AS (
    SELECT 
        car_name,
        car_class,
        average_position,
        race_count,
        RANK() OVER (PARTITION BY car_class ORDER BY average_position ASC) AS rank
    FROM 
        CarStats
)
SELECT 
    car_name,
    car_class,
    ROUND(average_position, 4) AS average_position,
    race_count
FROM 
    RankedCars
WHERE 
    rank = 1
ORDER BY 
    average_position;


-- ЗАДАНИЕ 2: Абсолютный лучший автомобиль
-- Найти автомобиль с наименьшей средней позицией
-- среди всех автомобилей

WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count,
        cl.country AS car_country
    FROM 
        Cars c
    INNER JOIN 
        Results r ON c.name = r.car
    INNER JOIN 
        Classes cl ON c.class = cl.class
    GROUP BY 
        c.name, c.class, cl.country
),
RankedCars AS (
    SELECT 
        car_name,
        car_class,
        average_position,
        race_count,
        car_country,
        ROW_NUMBER() OVER (ORDER BY average_position ASC, car_name ASC) AS rank
    FROM 
        CarStats
)
SELECT 
    car_name,
    car_class,
    ROUND(average_position, 4) AS average_position,
    race_count,
    car_country
FROM 
    RankedCars
WHERE 
    rank = 1;

-- ЗАДАНИЕ 3: Лучшие классы и все их автомобили
-- Найти классы с минимальной средней позицией
-- и вывести все автомобили из этих классов

WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS avg_car_position,
        COUNT(r.race) AS race_count,
        cl.country AS car_country
    FROM 
        Cars c
    INNER JOIN 
        Results r ON c.name = r.car
    INNER JOIN 
        Classes cl ON c.class = cl.class
    GROUP BY 
        c.name, c.class, cl.country
),
ClassAvg AS (
    SELECT 
        car_class,
        AVG(avg_car_position) AS avg_class_position
    FROM 
        CarStats
    GROUP BY 
        car_class
),
BestClasses AS (
    SELECT 
        car_class
    FROM 
        ClassAvg
    WHERE 
        avg_class_position = (SELECT MIN(avg_class_position) FROM ClassAvg)
),
ClassTotalRaces AS (
    SELECT 
        c.class AS car_class,
        COUNT(r.race) AS total_races
    FROM 
        Cars c
    INNER JOIN 
        Results r ON c.name = r.car
    GROUP BY 
        c.class
)
SELECT 
    cs.car_name,
    cs.car_class,
    ROUND(cs.avg_car_position, 4) AS average_position,
    cs.race_count,
    cs.car_country,
    ctr.total_races
FROM 
    CarStats cs
INNER JOIN 
    BestClasses bc ON cs.car_class = bc.car_class
INNER JOIN 
    ClassTotalRaces ctr ON cs.car_class = ctr.car_class
ORDER BY 
    cs.car_class,
    cs.car_name;


-- ЗАДАНИЕ 4: Автомобили лучше среднего по классу
-- Найти автомобили с позицией лучше средней
-- по своему классу (в классах с >= 2 авто)

WITH ClassCarCount AS (
    SELECT 
        c.class AS car_class,
        COUNT(DISTINCT c.name) AS cars_in_class
    FROM 
        Cars c
    GROUP BY 
        c.class
),
CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS avg_car_position,
        COUNT(r.race) AS race_count,
        cl.country AS car_country
    FROM 
        Cars c
    INNER JOIN 
        Results r ON c.name = r.car
    INNER JOIN 
        Classes cl ON c.class = cl.class
    GROUP BY 
        c.name, c.class, cl.country
),
ClassStats AS (
    SELECT 
        c.class AS car_class,
        AVG(r.position) AS avg_class_position
    FROM 
        Cars c
    INNER JOIN 
        Results r ON c.name = r.car
    GROUP BY 
        c.class
)
SELECT 
    cs.car_name,
    cs.car_class,
    ROUND(cs.avg_car_position, 4) AS average_position,
    cs.race_count,
    cs.car_country
FROM 
    CarStats cs
INNER JOIN 
    ClassCarCount ccc ON cs.car_class = ccc.car_class
INNER JOIN 
    ClassStats cs2 ON cs.car_class = cs2.car_class
WHERE 
    ccc.cars_in_class >= 2
    AND cs.avg_car_position < cs2.avg_class_position
ORDER BY 
    cs.car_class,
    cs.avg_car_position;


-- ЗАДАНИЕ 5: Классы с плохими автомобилями
-- Найти классы с наибольшим количеством автомобилей
-- с низкой позицией (> 3.0)

WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS avg_car_position,
        COUNT(r.race) AS race_count,
        cl.country AS car_country
    FROM 
        Cars c
    INNER JOIN 
        Results r ON c.name = r.car
    INNER JOIN 
        Classes cl ON c.class = cl.class
    GROUP BY 
        c.name, c.class, cl.country
),
ClassLowCount AS (
    SELECT 
        car_class,
        COUNT(*) AS low_position_count,
        SUM(race_count) AS total_races
    FROM 
        CarStats
    WHERE 
        avg_car_position > 3.0
    GROUP BY 
        car_class
),
BestClasses AS (
    SELECT 
        car_class,
        low_position_count,
        total_races,
        RANK() OVER (ORDER BY low_position_count DESC) AS rank
    FROM 
        ClassLowCount
)
SELECT 
    cs.car_name,
    cs.car_class,
    ROUND(cs.avg_car_position, 4) AS average_position,
    cs.race_count,
    cs.car_country,
    bc.total_races,
    bc.low_position_count
FROM 
    CarStats cs
INNER JOIN 
    BestClasses bc ON cs.car_class = bc.car_class
WHERE 
    bc.rank = 1
ORDER BY 
    bc.low_position_count DESC,
    cs.car_class,
    cs.car_name;