-- =========================================================================
-- ScanSmart – Universal Product Scanner & Smart Inventory
-- Database Schema: admin_panel.sql / grocery_admin_db
-- Compatible with XAMPP Localhost and InfinityFree Cloud Hosting
-- =========================================================================

CREATE DATABASE IF NOT EXISTS `grocery_admin_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `grocery_admin_db`;

-- 1. Admins Table (Role-Based Access: super_admin, admin, editor, viewer)
CREATE TABLE IF NOT EXISTS `admins` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `role` ENUM('super_admin', 'admin', 'editor', 'viewer') NOT NULL DEFAULT 'admin',
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `last_login` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Users Table (Mobile Application Registered Accounts)
CREATE TABLE IF NOT EXISTS `users` (
    `id` VARCHAR(64) PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `password` VARCHAR(255) NULL,
    `role` VARCHAR(50) NOT NULL DEFAULT 'user',
    `status` ENUM('active', 'inactive', 'banned') NOT NULL DEFAULT 'active',
    `products_count` INT NOT NULL DEFAULT 0,
    `scans_count` INT NOT NULL DEFAULT 0,
    `last_login` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_users_email` (`email`),
    INDEX `idx_users_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Categories Table (Universal Product Categories)
CREATE TABLE IF NOT EXISTS `categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `description` TEXT NULL,
    `icon` VARCHAR(50) DEFAULT 'category',
    `color` VARCHAR(20) DEFAULT '#10B981',
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `sort_order` INT NOT NULL DEFAULT 0,
    `image_url` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Subcategories Table
CREATE TABLE IF NOT EXISTS `subcategories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `sort_order` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_subcategories_cat` (`category_id`),
    CONSTRAINT `fk_subcategories_category` FOREIGN KEY (`category_id`)
        REFERENCES `categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Universal Products Table
CREATE TABLE IF NOT EXISTS `products` (
    `id` VARCHAR(64) PRIMARY KEY,
    `user_id` VARCHAR(64) NOT NULL DEFAULT 'default_user',
    `name` VARCHAR(255) NOT NULL,
    `brand` VARCHAR(150) NULL,
    `barcode` VARCHAR(100) NULL,
    `qr_code` VARCHAR(255) NULL,
    `image_path` TEXT NULL,
    `category` VARCHAR(100) NOT NULL DEFAULT 'Other',
    `category_id` INT NULL,
    `subcategory` VARCHAR(100) NULL,
    `subcategory_id` INT NULL,
    `description` TEXT NULL,
    `quantity` DECIMAL(10, 2) NOT NULL DEFAULT 1.00,
    `unit` VARCHAR(50) NOT NULL DEFAULT 'pieces',
    `purchase_price` DECIMAL(10, 2) NULL,
    `currency` VARCHAR(10) NOT NULL DEFAULT '₹',
    `purchase_date` DATE NULL,
    `manufacturing_date` DATE NULL,
    `expiry_date` DATE NULL,
    `reminder_date` DATETIME NULL,
    `reminder_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `reminder_days_before` VARCHAR(100) DEFAULT '7',
    `notification_id` INT NULL,
    `expiry_status` VARCHAR(50) NOT NULL DEFAULT 'Safe',
    `storage_location` VARCHAR(100) NOT NULL DEFAULT 'pantry',
    `manufacturer` VARCHAR(150) NULL,
    `country_of_origin` VARCHAR(100) NULL,
    `ingredients` TEXT NULL,
    `usage_instructions` TEXT NULL,
    `warranty_information` VARCHAR(255) NULL,
    `product_url` VARCHAR(500) NULL,
    `source` VARCHAR(50) NOT NULL DEFAULT 'Manual Entry',
    `category_confidence` INT NOT NULL DEFAULT 100,
    `review_status` ENUM('Approved', 'Pending Review', 'Rejected', 'Needs Correction') NOT NULL DEFAULT 'Approved',
    `status` ENUM('Active', 'Inactive', 'Pending Review', 'Needs Review', 'Archived') NOT NULL DEFAULT 'Active',
    `is_consumed` TINYINT(1) NOT NULL DEFAULT 0,
    `is_favorite` TINYINT(1) NOT NULL DEFAULT 0,
    `notes` TEXT NULL,
    `last_notification_sent` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_products_barcode` (`barcode`),
    INDEX `idx_products_category` (`category`),
    INDEX `idx_products_expiry` (`expiry_date`),
    INDEX `idx_products_user` (`user_id`),
    INDEX `idx_products_status` (`status`),
    INDEX `idx_products_review` (`review_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Inventory Records Table
CREATE TABLE IF NOT EXISTS `inventory` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(64) NOT NULL DEFAULT 'default_user',
    `product_id` VARCHAR(64) NOT NULL,
    `quantity` DECIMAL(10, 2) NOT NULL DEFAULT 1.00,
    `unit` VARCHAR(50) NOT NULL DEFAULT 'pieces',
    `purchase_price` DECIMAL(10, 2) NULL,
    `purchase_date` DATE NULL,
    `expiry_date` DATE NULL,
    `storage_location` VARCHAR(100) NOT NULL DEFAULT 'pantry',
    `notes` TEXT NULL,
    `status` ENUM('In Stock', 'Low Stock', 'Out of Stock', 'Archived') NOT NULL DEFAULT 'In Stock',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_inventory_user` (`user_id`),
    INDEX `idx_inventory_product` (`product_id`),
    INDEX `idx_inventory_status` (`status`),
    CONSTRAINT `fk_inventory_product` FOREIGN KEY (`product_id`)
        REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Product Expiration Reminders Table
CREATE TABLE IF NOT EXISTS `product_reminders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(64) NOT NULL DEFAULT 'default_user',
    `product_id` VARCHAR(64) NOT NULL,
    `reminder_date` DATETIME NOT NULL,
    `days_before_expiry` INT NOT NULL DEFAULT 7,
    `notification_id` INT NOT NULL,
    `is_sent` TINYINT(1) NOT NULL DEFAULT 0,
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `last_sent_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_reminders_product` (`product_id`),
    INDEX `idx_reminders_user` (`user_id`),
    INDEX `idx_reminders_date` (`reminder_date`),
    INDEX `idx_reminders_sent` (`is_sent`),
    CONSTRAINT `fk_reminders_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Scan History Table
CREATE TABLE IF NOT EXISTS `scan_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(64) NOT NULL DEFAULT 'default_user',
    `barcode` VARCHAR(100) NULL,
    `scan_type` ENUM('Barcode', 'QR Code', 'OCR', 'Manual Entry') NOT NULL DEFAULT 'Barcode',
    `product_found` TINYINT(1) NOT NULL DEFAULT 1,
    `product_id` VARCHAR(64) NULL,
    `product_name` VARCHAR(255) NULL,
    `scan_result` TEXT NULL,
    `scan_date` DATE NOT NULL,
    `scan_time` TIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_scans_barcode` (`barcode`),
    INDEX `idx_scans_user` (`user_id`),
    INDEX `idx_scans_date` (`scan_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Unknown Products Queue Table
CREATE TABLE IF NOT EXISTS `unknown_products` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `barcode` VARCHAR(100) NOT NULL,
    `product_name` VARCHAR(255) NULL,
    `ocr_text` TEXT NULL,
    `user_id` VARCHAR(64) NOT NULL DEFAULT 'default_user',
    `scan_type` VARCHAR(50) NOT NULL DEFAULT 'Barcode',
    `image_url` TEXT NULL,
    `suggested_category` VARCHAR(100) NULL,
    `suggested_subcategory` VARCHAR(100) NULL,
    `review_status` ENUM('Pending Review', 'Approved', 'Rejected', 'Needs Information') NOT NULL DEFAULT 'Pending Review',
    `admin_notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_unknown_barcode` (`barcode`),
    INDEX `idx_unknown_status` (`review_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Category Keywords Table (Automatic Categorization Engine)
CREATE TABLE IF NOT EXISTS `category_keywords` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_id` INT NOT NULL,
    `keyword` VARCHAR(100) NOT NULL,
    `subcategory_name` VARCHAR(100) NULL,
    `confidence_score` INT NOT NULL DEFAULT 90,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_cat_keyword` (`keyword`),
    CONSTRAINT `fk_keywords_category` FOREIGN KEY (`category_id`)
        REFERENCES `categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Admin Activity Logs Table
CREATE TABLE IF NOT EXISTS `admin_activity_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_id` INT NULL,
    `admin_name` VARCHAR(100) NULL,
    `action` VARCHAR(100) NOT NULL,
    `description` TEXT NOT NULL,
    `ip_address` VARCHAR(45) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_logs_admin` (`admin_id`),
    INDEX `idx_logs_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Product Secondary Images Table
CREATE TABLE IF NOT EXISTS `product_images` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_id` VARCHAR(64) NOT NULL,
    `image_url` TEXT NOT NULL,
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_pimages_prod` (`product_id`),
    CONSTRAINT `fk_pimages_product` FOREIGN KEY (`product_id`)
        REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Application Settings Table
CREATE TABLE IF NOT EXISTS `app_settings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) NOT NULL UNIQUE,
    `setting_value` TEXT NULL,
    `description` VARCHAR(255) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. Recipes & Ingredients & Announcements (Preserved for compatibility)
CREATE TABLE IF NOT EXISTS `recipes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `category_id` INT NULL,
    `description` TEXT NULL,
    `image_url` VARCHAR(500) NULL,
    `youtube_id` VARCHAR(50) NULL,
    `youtube_url` VARCHAR(255) NULL,
    `prep_time` VARCHAR(50) NOT NULL DEFAULT '15 mins',
    `difficulty` ENUM('Easy', 'Medium', 'Hard') NOT NULL DEFAULT 'Easy',
    `calories` INT NOT NULL DEFAULT 0,
    `instructions` TEXT NULL,
    `status` ENUM('published', 'draft') NOT NULL DEFAULT 'published',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `recipe_ingredients` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `recipe_id` INT NOT NULL,
    `ingredient_name` VARCHAR(150) NOT NULL,
    `quantity` VARCHAR(50) NULL,
    `unit` VARCHAR(50) NULL,
    `is_required` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_ingredients_recipe` FOREIGN KEY (`recipe_id`) 
        REFERENCES `recipes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `announcements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `message` TEXT NOT NULL,
    `image_url` VARCHAR(500) NULL,
    `status` ENUM('published', 'draft', 'archived') NOT NULL DEFAULT 'published',
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================================
-- INITIAL SEED DATA
-- =========================================================================

-- Super Admin Account (Password: admin123)
INSERT INTO `admins` (`id`, `name`, `email`, `password`, `role`, `status`) VALUES
(1, 'ScanSmart Administrator', 'admin@scansmart.com', '$2y$10$SYTaPyrYaLYkOgdicdJRp.GDSAuipnk3xEto0Ne06Ycwt97XmHeYu', 'super_admin', 'active')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Default Demo User
INSERT INTO `users` (`id`, `name`, `email`, `role`, `status`, `products_count`, `scans_count`) VALUES
('default_user', 'Demo User', 'user@scansmart.com', 'user', 'active', 6, 12)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 12 Standard Universal Categories
INSERT INTO `categories` (`id`, `name`, `description`, `icon`, `color`, `status`, `sort_order`) VALUES
(1, 'Food & Beverages', 'Fresh groceries, pantry staples, dairy, beverages, snacks and meals.', 'restaurant', '#10B981', 'active', 1),
(2, 'Personal Care', 'Skincare, haircare, oral hygiene, cosmetics, soaps and grooming.', 'spa', '#EC4899', 'active', 2),
(3, 'Healthcare', 'Medicines, vitamins, supplements, first aid, thermometers and medical supplies.', 'medical_services', '#EF4444', 'active', 3),
(4, 'Electronics', 'Gadgets, batteries, cables, earphones, chargers and appliances.', 'devices', '#3B82F6', 'active', 4),
(5, 'Clothing & Fashion', 'Apparel, footwear, accessories, fabrics and seasonal clothing.', 'checkroom', '#8B5CF6', 'active', 5),
(6, 'Household', 'Cleaning supplies, detergents, kitchenware, paper products and decor.', 'home', '#F59E0B', 'active', 6),
(7, 'Books & Stationery', 'Books, notebooks, pens, office supplies, art materials and papers.', 'menu_book', '#06B6D4', 'active', 7),
(8, 'Automotive', 'Car care, motor oils, wipers, tire sealants and vehicle accessories.', 'directions_car', '#64748B', 'active', 8),
(9, 'Sports & Fitness', 'Fitness gear, protein powders, balls, mats and sports nutrition.', 'fitness_center', '#14B8A6', 'active', 9),
(10, 'Baby Products', 'Baby food, diapers, wipes, formula, baby skincare and toys.', 'child_care', '#F43F5E', 'active', 10),
(11, 'Pet Supplies', 'Pet food, treats, pet shampoo, toys, litter and pet healthcare.', 'pets', '#D97706', 'active', 11),
(12, 'Other', 'Miscellaneous household items, tools and uncategorized goods.', 'category', '#6B7280', 'active', 12)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Subcategories for Categories
INSERT INTO `subcategories` (`id`, `category_id`, `name`, `description`) VALUES
(1, 1, 'Fresh Produce', 'Fruits, vegetables and herbs'),
(2, 1, 'Dairy & Eggs', 'Milk, yogurt, cheese, butter and eggs'),
(3, 1, 'Pantry Staples', 'Grains, flour, oils, pasta, rice and pulses'),
(4, 1, 'Snacks & Packaged', 'Biscuits, crackers, chips and ready-to-eat'),
(5, 1, 'Beverages', 'Tea, coffee, juices and bottled drinks'),
(6, 2, 'Skincare', 'Lotions, moisturizers, sunscreen and serums'),
(7, 2, 'Haircare', 'Shampoos, conditioners, oils and hair colors'),
(8, 2, 'Oral Hygiene', 'Toothpaste, toothbrushes, mouthwash and floss'),
(9, 3, 'Medicines & Pain Relief', 'Analgesics, cough syrups, cold medications'),
(10, 3, 'Vitamins & Supplements', 'Multivitamins, omega 3, protein, vitamin C'),
(11, 4, 'Audio & Accessories', 'Headphones, earphones, speakers and adapters'),
(12, 4, 'Batteries & Power', 'Rechargeable batteries, AA, AAA, power banks'),
(13, 6, 'Cleaning & Detergents', 'Dish wash, floor cleaner, laundry pods and sprays')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Category Keywords for Smart Classification
INSERT INTO `category_keywords` (`category_id`, `keyword`, `subcategory_name`, `confidence_score`) VALUES
(1, 'milk', 'Dairy & Eggs', 98),
(1, 'cheese', 'Dairy & Eggs', 96),
(1, 'yogurt', 'Dairy & Eggs', 97),
(1, 'biscuit', 'Snacks & Packaged', 94),
(1, 'tea', 'Beverages', 95),
(1, 'coffee', 'Beverages', 95),
(2, 'shampoo', 'Haircare', 96),
(2, 'soap', 'Skincare', 92),
(2, 'lotion', 'Skincare', 95),
(2, 'toothpaste', 'Oral Hygiene', 98),
(3, 'paracetamol', 'Medicines & Pain Relief', 98),
(3, 'crocin', 'Medicines & Pain Relief', 98),
(3, 'aspirin', 'Medicines & Pain Relief', 98),
(3, 'vitamin', 'Vitamins & Supplements', 95),
(4, 'battery', 'Batteries & Power', 96),
(4, 'headphone', 'Audio & Accessories', 97),
(6, 'detergent', 'Cleaning & Detergents', 96),
(6, 'cleaner', 'Cleaning & Detergents', 94)
ON DUPLICATE KEY UPDATE `keyword` = VALUES(`keyword`);

-- Application Settings
INSERT INTO `app_settings` (`id`, `setting_key`, `setting_value`, `description`) VALUES
(1, 'app_name', 'ScanSmart – Universal Product Scanner & Smart Inventory', 'Display name of application'),
(2, 'app_tagline', 'Scan Anything. Know Everything. Never Miss an Expiry.', 'Application brand tagline'),
(3, 'admin_email', 'admin@scansmart.com', 'Primary administrator email'),
(4, 'default_currency', '₹', 'Primary currency symbol'),
(5, 'default_reminder_days', '7', 'Default days before expiry to alert user'),
(6, 'enable_reminders', '1', 'Master switch for product expiry reminders'),
(7, 'default_product_status', 'Active', 'Default status for newly scanned products'),
(8, 'pagination_limit', '20', 'Items displayed per page in admin tables'),
(9, 'max_upload_mb', '5', 'Maximum image upload size in MB'),
(10, 'maintenance_mode', '0', 'System maintenance mode toggle (0=Off, 1=On)')
ON DUPLICATE KEY UPDATE `setting_value` = VALUES(`setting_value`);
