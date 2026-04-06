Итоговое задание по базам данных.
Базы данных были созданы в pgAdmin4. В папке базы данных по каждому заданию. 

#База данных 1

##Задание 1:
```sql
SELECT 
    v.maker,
    m.model
FROM 
    Vehicle v
INNER JOIN 
    motorcycle m ON v.model = m.model
WHERE 
    v.type = 'Motorcycle'
    AND m.type = 'Sport'
    AND m.horsepower > 150
    AND m.price < 20000
ORDER BY 
    m.horsepower DESC;
```markdown
##Задание 2:
```sql
SELECT 
    maker,
    model,
    horsepower,
    engine_capacity,
    type
FROM (
    -- Автомобили
    SELECT 
        v.maker,
        v.model,
        c.horsepower,
        c.engine_capacity,
        'Car' AS type
    FROM 
        Vehicle v
    INNER JOIN 
        Car c ON v.model = c.model
    WHERE 
        c.horsepower > 150
        AND c.engine_capacity < 3.0
        AND c.price < 35000

    UNION ALL

    -- Мотоциклы
    SELECT 
        v.maker,
        v.model,
        m.horsepower,
        m.engine_capacity,
        'Motorcycle' AS type
    FROM 
        Vehicle v
    INNER JOIN 
        Motorcycle m ON v.model = m.model
    WHERE 
        m.horsepower > 150
        AND m.engine_capacity < 1.5
        AND m.price < 20000

    UNION ALL

    -- Велосипеды
    SELECT 
        v.maker,
        v.model,
        NULL::INT AS horsepower,
        NULL::NUMERIC AS engine_capacity,
        'Bicycle' AS type
    FROM 
        Vehicle v
    INNER JOIN 
        Bicycle b ON v.model = b.model
    WHERE 
        b.gear_count > 18
        AND b.price < 4000
) AS all_vehicles
ORDER BY 
    horsepower IS NULL,  -- FALSE (0) сначала, TRUE (1) потом
    horsepower DESC;
```markdown
#База данных 2

##Задание 1:
```sql
WITH CarStats AS (
    -- Шаг 1: Рассчитываем среднюю позицию и количество гонок для каждого автомобиля
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
    -- Шаг 2: Для каждого класса находим автомобиль с наилучшей (минимальной) средней позицией
    SELECT 
        car_name,
        car_class,
        average_position,
        race_count,
        RANK() OVER (PARTITION BY car_class ORDER BY average_position ASC) AS rank
    FROM 
        CarStats
)
-- Шаг 3: Выбираем только те автомобили, которые имеют лучшую среднюю позицию в своём классе
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
```markdown
##Задание 2:
```sql
WITH CarStats AS (
    -- Шаг 1: Рассчитываем среднюю позицию и количество гонок для каждого автомобиля
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
    -- Шаг 2: Ранжируем все автомобили по средней позиции (чем меньше, тем лучше)
    -- и по имени для разрешения конфликтов
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
-- Шаг 3: Выбираем автомобиль с rank = 1
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
```markdown
##Задание 3:
```sql
WITH CarStats AS (
    -- Средняя позиция каждого автомобиля
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
    -- Средняя позиция каждого класса (по средним позициям автомобилей)
    SELECT 
        car_class,
        AVG(avg_car_position) AS avg_class_position
    FROM 
        CarStats
    GROUP BY 
        car_class
),
BestClasses AS (
    -- Классы с минимальной средней позицией
    SELECT 
        car_class
    FROM 
        ClassAvg
    WHERE 
        avg_class_position = (SELECT MIN(avg_class_position) FROM ClassAvg)
),
ClassTotalRaces AS (
    -- Общее количество гонок для каждого класса
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
-- Финальный вывод
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
```markdown
##Задание 4:
```sql
WITH ClassCarCount AS (
    -- Шаг 1: Количество автомобилей в каждом классе (без оконной функции)
    SELECT 
        c.class AS car_class,
        COUNT(DISTINCT c.name) AS cars_in_class
    FROM 
        Cars c
    GROUP BY 
        c.class
),
CarStats AS (
    -- Шаг 2: Статистика каждого автомобиля
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
    -- Шаг 3: Средняя позиция по каждому классу
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
-- Шаг 4: Финальный вывод
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
```markdown
##Задание 5:
```sql
WITH CarStats AS (
    -- Шаг 1: Средняя позиция каждого автомобиля
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
    -- Шаг 2: Количество автомобилей с низкой позицией (> 3.0) в каждом классе
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
    -- Шаг 3: Классы с максимальным количеством таких автомобилей
    SELECT 
        car_class,
        low_position_count,
        total_races,
        RANK() OVER (ORDER BY low_position_count DESC) AS rank
    FROM 
        ClassLowCount
)
-- Шаг 4: Все автомобили из лучших классов
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
```markdown
#База данных 3

##Задание 1:
```sql
WITH CustomerBookings AS (
    -- Шаг 1: Базовая информация о бронированиях с длительностью
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
    -- Шаг 2: Агрегация по клиенту
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
-- Шаг 3: Фильтрация клиентов с более чем 2 бронированиями в разных отелях
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
    AND distinct_hotels > 1  -- бронирования в разных отелях
ORDER BY 
    total_bookings DESC;
```markdown
##Задание 2:
```sql
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
```markdown
##Задание 3:
```sql
WITH HotelCategory AS (
    -- Шаг 1: Категоризация отелей на основе средней стоимости номера
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
    -- Шаг 2: Для каждого клиента - список отелей и их категории
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
    -- Шаг 3: Определение предпочитаемой категории для каждого клиента
    SELECT 
        ID_customer,
        name,
        STRING_AGG(DISTINCT hotel_name, ', ' ORDER BY hotel_name) AS visited_hotels,
        CASE 
            -- Если есть хотя бы один "Дорогой"
            WHEN MAX(CASE WHEN hotel_category = 'Дорогой' THEN 1 ELSE 0 END) = 1 THEN 'Дорогой'
            -- Если нет "Дорогих", но есть хотя бы один "Средний"
            WHEN MAX(CASE WHEN hotel_category = 'Средний' THEN 1 ELSE 0 END) = 1 THEN 'Средний'
            -- Иначе "Дешевый"
            ELSE 'Дешевый'
        END AS preferred_hotel_type
    FROM 
        CustomerVisits
    GROUP BY 
        ID_customer, name
)
-- Шаг 4: Финальный вывод с сортировкой
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
```markdown
#База данных 4

##Задание 1:
```sql
WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый уровень: сам Иван Иванов
    SELECT 
        EmployeeID,
        Name,
        ManagerID,
        DepartmentID,
        RoleID
    FROM 
        Employees
    WHERE 
        EmployeeID = 1
    
    UNION ALL
    
    -- Рекурсивный уровень: подчинённые
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM 
        Employees e
    INNER JOIN 
        EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
),
EmployeeProjects AS (
    -- Проекты сотрудников (через отделы)
    SELECT 
        e.EmployeeID,
        STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName) AS ProjectNames
    FROM 
        EmployeeHierarchy e
    LEFT JOIN 
        Projects p ON e.DepartmentID = p.DepartmentID
    GROUP BY 
        e.EmployeeID
),
EmployeeTasks AS (
    -- Задачи сотрудников
    SELECT 
        e.EmployeeID,
        STRING_AGG(DISTINCT t.TaskName, ', ' ORDER BY t.TaskName) AS TaskNames
    FROM 
        EmployeeHierarchy e
    LEFT JOIN 
        Tasks t ON e.EmployeeID = t.AssignedTo
    GROUP BY 
        e.EmployeeID
)
-- Финальный вывод
SELECT 
    eh.EmployeeID,
    eh.Name AS EmployeeName,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    ep.ProjectNames,
    et.TaskNames
FROM 
    EmployeeHierarchy eh
LEFT JOIN 
    Departments d ON eh.DepartmentID = d.DepartmentID
LEFT JOIN 
    Roles r ON eh.RoleID = r.RoleID
LEFT JOIN 
    EmployeeProjects ep ON eh.EmployeeID = ep.EmployeeID
LEFT JOIN 
    EmployeeTasks et ON eh.EmployeeID = et.EmployeeID
ORDER BY 
    eh.Name;
```markdown
##Задание 2:
```sql
WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый уровень: сам Иван Иванов
    SELECT 
        EmployeeID,
        Name,
        ManagerID,
        DepartmentID,
        RoleID
    FROM 
        Employees
    WHERE 
        EmployeeID = 1
    
    UNION ALL
    
    -- Рекурсивный уровень: подчинённые
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM 
        Employees e
    INNER JOIN 
        EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
),
EmployeeProjects AS (
    -- Проекты сотрудников (через отделы)
    SELECT 
        eh.EmployeeID,
        STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName) AS ProjectNames
    FROM 
        EmployeeHierarchy eh
    LEFT JOIN 
        Projects p ON eh.DepartmentID = p.DepartmentID
    GROUP BY 
        eh.EmployeeID
),
EmployeeTasks AS (
    -- Задачи сотрудников
    SELECT 
        eh.EmployeeID,
        STRING_AGG(DISTINCT t.TaskName, ', ' ORDER BY t.TaskName) AS TaskNames,
        COUNT(DISTINCT t.TaskID) AS TotalTasks
    FROM 
        EmployeeHierarchy eh
    LEFT JOIN 
        Tasks t ON eh.EmployeeID = t.AssignedTo
    GROUP BY 
        eh.EmployeeID
),
SubordinateCount AS (
    -- Количество прямых подчинённых (только непосредственные)
    SELECT 
        ManagerID,
        COUNT(*) AS TotalSubordinates
    FROM 
        Employees
    GROUP BY 
        ManagerID
)
-- Финальный вывод
SELECT 
    eh.EmployeeID,
    eh.Name AS EmployeeName,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    ep.ProjectNames,
    et.TaskNames,
    COALESCE(et.TotalTasks, 0) AS TotalTasks,
    COALESCE(sc.TotalSubordinates, 0) AS TotalSubordinates
FROM 
    EmployeeHierarchy eh
LEFT JOIN 
    Departments d ON eh.DepartmentID = d.DepartmentID
LEFT JOIN 
    Roles r ON eh.RoleID = r.RoleID
LEFT JOIN 
    EmployeeProjects ep ON eh.EmployeeID = ep.EmployeeID
LEFT JOIN 
    EmployeeTasks et ON eh.EmployeeID = et.EmployeeID
LEFT JOIN 
    SubordinateCount sc ON eh.EmployeeID = sc.ManagerID
ORDER BY 
    eh.Name;
```markdown
##Задание 3:
```sql
WITH RECURSIVE SubordinateHierarchy AS (
    -- Базовый уровень: все сотрудники (как потенциальные менеджеры)
    SELECT 
        EmployeeID,
        ManagerID
    FROM 
        Employees
    
    UNION ALL
    
    -- Рекурсивный уровень: подчинённые подчинённых
    SELECT 
        e.EmployeeID,
        sh.ManagerID
    FROM 
        Employees e
    INNER JOIN


SubordinateHierarchy sh ON e.ManagerID = sh.EmployeeID
),
AllManagers AS (
    -- Только сотрудники с ролью "Менеджер" (RoleID = 1)
    SELECT 
        EmployeeID
    FROM 
        Employees
    WHERE 
        RoleID = 1
),
SubordinateCount AS (
    -- Подсчёт всех подчинённых для каждого менеджера (включая косвенных)
    SELECT 
        sh.ManagerID AS EmployeeID,
        COUNT(DISTINCT sh.EmployeeID) AS TotalSubordinates
    FROM 
        SubordinateHierarchy sh
    WHERE 
        sh.ManagerID IN (SELECT EmployeeID FROM AllManagers)
    GROUP BY 
        sh.ManagerID
    HAVING 
        COUNT(DISTINCT sh.EmployeeID) > 0
),
EmployeeProjects AS (
    -- Проекты сотрудников (через отделы)
    SELECT 
        e.EmployeeID,
        STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName) AS ProjectNames
    FROM 
        Employees e
    LEFT JOIN 
        Projects p ON e.DepartmentID = p.DepartmentID
    GROUP BY 
        e.EmployeeID
),
EmployeeTasks AS (
    -- Задачи сотрудников
    SELECT 
        e.EmployeeID,
        STRING_AGG(DISTINCT t.TaskName, ', ' ORDER BY t.TaskName) AS TaskNames
    FROM 
        Employees e
    LEFT JOIN 
        Tasks t ON e.EmployeeID = t.AssignedTo
    GROUP BY 
        e.EmployeeID
)
-- Финальный вывод
SELECT 
    e.EmployeeID,
    e.Name AS EmployeeName,
    e.ManagerID,
    d.DepartmentName,
    r.RoleName,
    ep.ProjectNames,
    et.TaskNames,
    sc.TotalSubordinates
FROM 
    Employees e
INNER JOIN 
    SubordinateCount sc ON e.EmployeeID = sc.EmployeeID
LEFT JOIN 
    Departments d ON e.DepartmentID = d.DepartmentID
LEFT JOIN 
    Roles r ON e.RoleID = r.RoleID
LEFT JOIN 
    EmployeeProjects ep ON e.EmployeeID = ep.EmployeeID
LEFT JOIN 
    EmployeeTasks et ON e.EmployeeID = et.EmployeeID
WHERE 
    e.RoleID = 1  -- Только менеджеры
    AND sc.TotalSubordinates > 0
ORDER BY 
    e.EmployeeID;
