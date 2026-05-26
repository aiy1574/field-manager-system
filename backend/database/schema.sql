CREATE DATABASE IF NOT EXISTS field_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE field_manager;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(50), position VARCHAR(100),
  role ENUM('admin','staff','sales','checkin') NOT NULL DEFAULT 'staff',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(50), email VARCHAR(150), note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE fields (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE pricing_rules (
  id INT AUTO_INCREMENT PRIMARY KEY,
  field_id INT NULL,
  hour_start INT NOT NULL,
  hour_end INT NOT NULL,
  price_per_hour DECIMAL(10,2) NOT NULL,
  label VARCHAR(100),
  FOREIGN KEY(field_id) REFERENCES fields(id) ON DELETE CASCADE
);
CREATE TABLE bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  field_id INT NOT NULL,
  customer_id INT NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  status ENUM('booked','checked_in','cancelled') NOT NULL DEFAULT 'booked',
  paid BOOLEAN NOT NULL DEFAULT FALSE,
  paid_at DATETIME NULL,
  checked_in_at DATETIME NULL,
  note TEXT,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(field_id) REFERENCES fields(id),
  FOREIGN KEY(customer_id) REFERENCES customers(id),
  FOREIGN KEY(created_by) REFERENCES users(id),
  INDEX idx_bookings_date(booking_date), INDEX idx_bookings_field(field_id)
);
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(80), name VARCHAR(150) NOT NULL, category VARCHAR(100),
  price DECIMAL(10,2) NOT NULL DEFAULT 0, cost DECIMAL(10,2) NOT NULL DEFAULT 0,
  stock INT NOT NULL DEFAULT 0, is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE sales (
  id INT AUTO_INCREMENT PRIMARY KEY,
  receipt_no VARCHAR(50) NOT NULL UNIQUE DEFAULT (CONCAT('R', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'))),
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_method VARCHAR(50) NOT NULL DEFAULT 'cash',
  customer_id INT NULL, sold_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(customer_id) REFERENCES customers(id), FOREIGN KEY(sold_by) REFERENCES users(id)
);
CREATE TABLE sale_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sale_id INT NOT NULL, product_id INT NOT NULL,
  product_name VARCHAR(150) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL, qty INT NOT NULL, subtotal DECIMAL(10,2) NOT NULL,
  FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id)
);
CREATE TABLE expenses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  expense_date DATE NOT NULL DEFAULT (CURRENT_DATE),
  category VARCHAR(100) NOT NULL,
  description TEXT,
  amount DECIMAL(10,2) NOT NULL,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(created_by) REFERENCES users(id)
);
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'info',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO fields(name, description) VALUES ('สนาม 1','สนามฟุตบอลหญ้าเทียม'),('สนาม 2','สนามฟุตบอลหญ้าเทียม');
INSERT INTO pricing_rules(field_id,hour_start,hour_end,price_per_hour,label)
SELECT id,9,17,400,'ช่วงกลางวัน' FROM fields UNION ALL SELECT id,17,22,700,'ช่วงเย็น' FROM fields UNION ALL SELECT id,22,24,500,'ช่วงดึก' FROM fields;
INSERT INTO products(name,category,price,cost,stock) VALUES ('น้ำดื่ม 600ml','เครื่องดื่ม',15,7,100),('น้ำอัดลม','เครื่องดื่ม',25,12,80),('เครื่องดื่มเกลือแร่','เครื่องดื่ม',30,18,60),('ผ้าเช็ดตัว','อุปกรณ์',120,60,20),('ถุงเท้าฟุตบอล','อุปกรณ์',90,40,30);
