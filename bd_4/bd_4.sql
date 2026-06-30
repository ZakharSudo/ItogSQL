-- БАЗА ДАННЫХ 4 - ВСЕ ЗАДАНИЯ


-- ЗАДАНИЕ 1: Все подчиненные Ивана Иванова
-- Рекурсивно найти всех сотрудников,
-- подчиняющихся Ивану Иванову (EmployeeID = 1)


WITH RECURSIVE EmployeeHierarchy AS (
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


-- ЗАДАНИЕ 2: С подсчетом задач и подчиненных
-- Добавить подсчет количества задач
-- и прямых подчиненных для каждого сотрудника

WITH RECURSIVE EmployeeHierarchy AS (
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
    SELECT 
        ManagerID,
        COUNT(*) AS TotalSubordinates
    FROM 
        Employees
    GROUP BY 
        ManagerID
)
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


-- ЗАДАНИЕ 3: Менеджеры с подчиненными
-- Найти всех менеджеров (RoleID = 1),
-- у которых есть подчиненные (включая косвенных)

WITH RECURSIVE SubordinateHierarchy AS (
    SELECT 
        EmployeeID,
        ManagerID
    FROM 
        Employees
    
    UNION ALL
    
    SELECT 
        e.EmployeeID,
        sh.ManagerID
    FROM 
        Employees e
    INNER JOIN
        SubordinateHierarchy sh ON e.ManagerID = sh.EmployeeID
),
AllManagers AS (
    SELECT 
        EmployeeID
    FROM 
        Employees
    WHERE 
        RoleID = 1
),
SubordinateCount AS (
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
    e.RoleID = 1
    AND sc.TotalSubordinates > 0
ORDER BY 
    e.EmployeeID;