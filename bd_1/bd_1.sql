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