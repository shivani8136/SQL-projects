-- Create 'departments' table
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    manager_id INT
);

-- Create 'employees' table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    hire_date DATE,
    job_title VARCHAR(50),
    department_id INT REFERENCES departments(id)
);

-- Create 'projects' table
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    start_date DATE,
    end_date DATE,
    department_id INT REFERENCES departments(id)
);

-- Insert data into 'departments'
INSERT INTO departments (name, manager_id)
VALUES ('HR', 1), ('IT', 2), ('Sales', 3);

-- Insert data into 'employees'
INSERT INTO employees (name, hire_date, job_title, department_id)
VALUES ('John Doe', '2018-06-20', 'HR Manager', 1),
       ('Jane Smith', '2019-07-15', 'IT Manager', 2),
       ('Alice Johnson', '2020-01-10', 'Sales Manager', 3),
       ('Bob Miller', '2021-04-30', 'HR Associate', 1),
       ('Charlie Brown', '2022-10-01', 'IT Associate', 2),
       ('Dave Davis', '2023-03-15', 'Sales Associate', 3);

-- Insert data into 'projects'
INSERT INTO projects (name, start_date, end_date, department_id)
VALUES ('HR Project 1', '2023-01-01', '2023-06-30', 1),
       ('IT Project 1', '2023-02-01', '2023-07-31', 2),
       ('Sales Project 1', '2023-03-01', '2023-08-31', 3);
       
UPDATE departments
SET manager_id = (SELECT id FROM employees WHERE name = 'John Doe')
WHERE name = 'HR';

UPDATE departments
SET manager_id = (SELECT id FROM employees WHERE name = 'Jane Smith')
WHERE name = 'IT';

UPDATE departments
SET manager_id = (SELECT id FROM employees WHERE name = 'Alice Johnson')
WHERE name = 'Sales';

-- SQL Challenge Questions

-- 1. Find the longest ongoing project for each department.
SELECT d.name AS department_name, p.id AS project_id, p.name AS project_name, DATEDIFF(p.end_date,p.start_date) AS duration_in_days FROM departments d JOIN projects p ON d.id=p.department_id;

-- 2. Find all employees who are not managers.
SELECT name AS employee_name, job_title FROM employees WHERE job_title NOT LIKE "%Manager";

-- 3. Find all employees who have been hired after the start of a project in their department.
SELECT e.name AS employee_name, e.hire_date, e.job_title, p.name AS project_name, p.start_date AS project_start_date  FROM employees e JOIN projects p ON  e.department_id=p.department_id WHERE e.hire_date > p.start_date;

-- 4. Rank employees within each department based on their hire date (earliest hire gets the highest rank).
WITH CTE1 AS (SELECT *, DENSE_RANK() OVER(PARTITION BY department_id ORDER BY hire_date) AS rn FROM employees) SELECT d.name AS department_name, e.name AS employee_name, e.hire_date , e.rn AS `rank` FROM CTE1 e JOIN departments d ON e.department_id=d.id ORDER BY d.name, e.rn;

-- 5. Find the duration between the hire date of each employee and the hire date of the next employee hired in the same department.
WITH CTE2 AS (SELECT MAX(hire_date) AS max_hire_date, MIN(hire_date) AS min_hire_date, department_id FROM employees GROUP BY department_id)SELECT d.name AS department_name, DATEDIFF(c.max_hire_date,c.min_hire_date) AS duration_between_hires_in_days FROM CTE2 c JOIN departments d ON c.department_id=d.id;