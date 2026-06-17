-- ============================================================
-- EBO Stay App - DB Migration
-- Run this on your existing database
-- ============================================================

-- 1. Add fcm_token + google_id to customers table
ALTER TABLE customers
    ADD COLUMN IF NOT EXISTS fcm_token  VARCHAR(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS google_id  VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS last_login DATETIME     DEFAULT NULL;

-- 2. Hotel bookings table (if not exists)
CREATE TABLE IF NOT EXISTS hotel_bookings (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    customer_id         INT NOT NULL,
    booking_ref         VARCHAR(30) NOT NULL UNIQUE,
    hotel_id            INT NOT NULL,
    room_id             INT NOT NULL,
    customer_name       VARCHAR(100) NOT NULL,
    customer_email      VARCHAR(150) NOT NULL,
    customer_phone      VARCHAR(20)  DEFAULT '',
    check_in            DATE NOT NULL,
    check_out           DATE NOT NULL,
    num_rooms           INT  DEFAULT 1,
    num_nights          INT  DEFAULT 1,
    total_amount        DECIMAL(10,2) NOT NULL,
    payment_status      ENUM('pending','paid','failed','refunded') DEFAULT 'pending',
    booking_status      ENUM('pending','confirmed','cancelled','completed') DEFAULT 'pending',
    razorpay_order_id   VARCHAR(100) DEFAULT NULL,
    razorpay_payment_id VARCHAR(100) DEFAULT NULL,
    special_requests    TEXT DEFAULT NULL,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (hotel_id)    REFERENCES hotels(id),
    FOREIGN KEY (room_id)     REFERENCES hotel_rooms(id)
);

-- 3. Activity bookings table (if not exists)
CREATE TABLE IF NOT EXISTS activity_bookings (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    customer_id         INT NOT NULL,
    booking_ref         VARCHAR(30) NOT NULL UNIQUE,
    activity_id         INT NOT NULL,
    customer_name       VARCHAR(100) NOT NULL,
    customer_email      VARCHAR(150) NOT NULL,
    customer_phone      VARCHAR(20)  DEFAULT '',
    activity_date       DATE NOT NULL,
    num_persons         INT  DEFAULT 1,
    total_amount        DECIMAL(10,2) NOT NULL,
    payment_status      ENUM('pending','paid','failed','refunded') DEFAULT 'pending',
    booking_status      ENUM('pending','confirmed','cancelled','completed') DEFAULT 'pending',
    razorpay_order_id   VARCHAR(100) DEFAULT NULL,
    razorpay_payment_id VARCHAR(100) DEFAULT NULL,
    notes               TEXT DEFAULT NULL,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (activity_id) REFERENCES activities(id)
);

-- 4. Activities table (if not exists from earlier migration)
CREATE TABLE IF NOT EXISTS activities (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    description TEXT DEFAULT NULL,
    price       DECIMAL(10,2) NOT NULL,
    duration    VARCHAR(50)  DEFAULT NULL,
    location    VARCHAR(200) DEFAULT NULL,
    category    VARCHAR(100) DEFAULT NULL,
    image       VARCHAR(255) DEFAULT NULL,
    is_active   TINYINT(1) DEFAULT 1,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 5. site_settings table for admin FCM token storage
CREATE TABLE IF NOT EXISTS site_settings (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    key_name   VARCHAR(100) NOT NULL UNIQUE,
    value      TEXT DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
);

-- Insert admin FCM token placeholder (update value from Firebase)
INSERT IGNORE INTO site_settings (key_name, value)
VALUES ('admin_fcm_token', NULL);

-- 6. Index for performance
ALTER TABLE hotel_bookings    ADD INDEX IF NOT EXISTS idx_customer (customer_id);
ALTER TABLE activity_bookings ADD INDEX IF NOT EXISTS idx_customer (customer_id);
ALTER TABLE bookings          ADD INDEX IF NOT EXISTS idx_razorpay_order (razorpay_order_id);
