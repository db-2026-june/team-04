-- ================================================================
-- SQL DDL TEMPLATE (TOPIC 04)
-- ================================================================
-- WHAT SHOULD BE ADDED HERE:
-- 1) Full PostgreSQL DDL for your finalized schema.
-- 2) CREATE TABLE statements for all entities from your ER diagram.
-- 3) Primary keys, foreign keys, NOT NULL, UNIQUE, CHECK constraints.
-- 4) Indexes for important search/join columns.
-- 5) Clean structure and comments (group by tables/constraints/indexes).
--
-- RECOMMENDED ORDER:
-- 1) Tables
-- 2) Constraints (if not inline)
-- 3) Indexes
--
-- TEAM NOTE:
-- Add short attribution comments for who implemented which part.
-- Example:
-- [Name] - users, roles, permissions tables
-- [Name] - orders, payments, invoices tables
--
-- Artem - Locations, Roles, Staff, Orders, OrderDetails tables
-- Victoria - MenuCategory, MenuItems, Ingredients, Customers, BasicInventory tables
--
-- IMPORTANT:
-- The script must run in PostgreSQL and produce a working schema that
-- matches your approved ER diagram and conceptual schema.
-- Submit this as one SQL file.
-- ================================================================

-- Add your DDL below this line

-- Схема бази даних для системи управління рестораном (RMS)
CREATE SCHEMA RMS;
 
-- Локації (філії) ресторану
CREATE TABLE RMS.Locations (
    location_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    location_city VARCHAR(50) NOT NULL,
    location_street VARCHAR(100) NOT NULL,
    location_building INT NOT NULL,
    location_phone VARCHAR(20) NOT NULL,
    location_email VARCHAR(254) NOT NULL,
    opening_time TIME NOT NULL,
    closing_time TIME NOT NULL,
    seating_capacity INT NOT NULL CHECK (seating_capacity >= 0)
);
 
-- Посади/ролі співробітників
CREATE TABLE RMS.Roles (
    role_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL
);
 
-- Співробітники, прив'язані до ролі та локації
CREATE TABLE RMS.Staff (
    employee_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    role_id INT NOT NULL REFERENCES RMS.Roles(role_id),
    location_id INT NOT NULL REFERENCES RMS.Locations(location_id),
    employee_fname VARCHAR(50) NOT NULL,
    employee_lname VARCHAR(50) NOT NULL,
    employee_phone VARCHAR(20) NOT NULL,
    employee_email VARCHAR(254) NOT NULL,
    hourly_rate DECIMAL(10, 2) NOT NULL CHECK (hourly_rate >= 0)
);
 
-- Категорії меню (наприклад, напої, десерти)
CREATE TABLE RMS.MenuCategory (
    category_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);
 
-- Позиції меню, кожна належить до певної категорії
CREATE TABLE RMS.MenuItems (
    item_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES RMS.MenuCategory(category_id),
    item_name VARCHAR(100) NOT NULL,
    item_description VARCHAR(500),
    preparation_time INT NOT NULL CHECK (preparation_time > 0),
    cost_price DECIMAL(10, 2) NOT NULL CHECK (cost_price >= 0),
    sell_price DECIMAL(10, 2) NOT NULL CHECK (sell_price >= 0)
);
 
-- Інгредієнти, що використовуються у стравах
CREATE TABLE RMS.Ingredients (
    ingredient_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    ingredient_name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL
);
 
-- Клієнти, що роблять замовлення
CREATE TABLE RMS.Customers (
    customer_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email_address VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    delivery_address VARCHAR(255)
);
 
-- Замовлення: локація, клієнт, співробітник, статус, тип, оплата
CREATE TABLE RMS.Orders (
    order_id INT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    location_id INT NOT NULL REFERENCES RMS.Locations(location_id),
    customer_id INT NOT NULL REFERENCES RMS.Customers(customer_id),
    employee_id INT NOT NULL REFERENCES RMS.Staff(employee_id),
    order_status VARCHAR(20) NOT NULL CHECK (order_status IN ('new', 'preparing', 'ready', 'delivering', 'completed', 'cancelled')),
    order_type VARCHAR(20) NOT NULL CHECK (order_type IN ('dine-in', 'takeaway', 'delivery')),
    order_datetime TIMESTAMP NOT NULL,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'terminal', 'in-app', 'crypto'))
);
 
-- Деталі замовлення: позиції меню в межах конкретного замовлення
CREATE TABLE RMS.OrderDetails (
    order_id INT NOT NULL REFERENCES RMS.Orders(order_id),
    item_id INT NOT NULL REFERENCES RMS.MenuItems(item_id),
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),
    total_price DECIMAL(10, 2) NOT NULL CHECK (total_price > 0),
    PRIMARY KEY (order_id, item_id)
);
 
-- Запаси інгредієнтів по кожній локації
CREATE TABLE RMS.BasicInventory (
    ingredient_id INT NOT NULL REFERENCES RMS.Ingredients(ingredient_id),
    location_id INT NOT NULL REFERENCES RMS.Locations(location_id),
    quantity_in_stock DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
    UNIQUE (ingredient_id, location_id)
);

-- Orders: найчастіші JOIN/WHERE — по клієнту, по локації, по співробітнику
CREATE INDEX idx_orders_customer_id ON RMS.Orders (customer_id);
CREATE INDEX idx_orders_location_id ON RMS.Orders (location_id);
CREATE INDEX idx_orders_employee_id ON RMS.Orders (employee_id);

-- Orders: звіти/фільтри за датою (наприклад, замовлення за сьогодні/за період)
CREATE INDEX idx_orders_order_datetime ON RMS.Orders (order_datetime);

-- OrderDetails: пошук усіх замовлень, де фігурує конкретна страва
CREATE INDEX idx_orderdetails_item_id ON RMS.OrderDetails (item_id);

-- BasicInventory: перегляд усіх залишків по конкретній локації
CREATE INDEX idx_basicinventory_location_id ON RMS.BasicInventory (location_id);
