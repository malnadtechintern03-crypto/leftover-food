-- Grocery Inventory & Expiry Tracking Admin Database Schema
-- Database: grocery_admin_db

CREATE DATABASE IF NOT EXISTS `grocery_admin_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `grocery_admin_db`;

-- 1. Admins Table
CREATE TABLE IF NOT EXISTS `admins` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `role` VARCHAR(50) NOT NULL DEFAULT 'admin',
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `last_login` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Grocery Categories Table (Groceries only)
CREATE TABLE IF NOT EXISTS `categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `description` TEXT NULL,
    `icon` VARCHAR(50) DEFAULT 'folder',
    `color` VARCHAR(20) DEFAULT '#10B981',
    `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Recipes Table
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
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_recipes_category` (`category_id`),
    INDEX `idx_recipes_status` (`status`),
    CONSTRAINT `fk_recipes_category` FOREIGN KEY (`category_id`) 
        REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Recipe Ingredients Table (Maps grocery items to recipes)
CREATE TABLE IF NOT EXISTS `recipe_ingredients` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `recipe_id` INT NOT NULL,
    `ingredient_name` VARCHAR(150) NOT NULL,
    `quantity` VARCHAR(50) NULL,
    `unit` VARCHAR(50) NULL,
    `is_required` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_recipe_ingredients_recipe` (`recipe_id`),
    CONSTRAINT `fk_ingredients_recipe` FOREIGN KEY (`recipe_id`) 
        REFERENCES `recipes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Announcements Table
CREATE TABLE IF NOT EXISTS `announcements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `message` TEXT NOT NULL,
    `image_url` VARCHAR(500) NULL,
    `status` ENUM('published', 'draft', 'archived') NOT NULL DEFAULT 'published',
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_announcements_dates` (`start_date`, `end_date`),
    INDEX `idx_announcements_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Application Settings Table
CREATE TABLE IF NOT EXISTS `app_settings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) NOT NULL UNIQUE,
    `setting_value` TEXT NULL,
    `description` VARCHAR(255) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- SEED DATA
-- ===================================================

-- 1. Initial Administrator Account
-- Password: admin123 (bcrypt hash)
INSERT INTO `admins` (`id`, `name`, `email`, `password`, `role`, `status`) VALUES
(1, 'Pantry Administrator', 'admin@homepantry.com', '$2y$10$SYTaPyrYaLYkOgdicdJRp.GDSAuipnk3xEto0Ne06Ycwt97XmHeYu', 'super_admin', 'active')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 2. Standard Grocery Categories (Grocery-Only Categories)
INSERT INTO `categories` (`id`, `name`, `description`, `icon`, `color`, `status`) VALUES
(1, 'Grains & Pulses', 'Whole grains, rice, lentils, dal, chickpeas, beans and dry pulses.', 'grain', '#10B981', 'active'),
(2, 'Flour & Baking', 'Wheat flour, atta, maida, baking powder, yeast, sugar and baking essentials.', 'bakery_dining', '#F59E0B', 'active'),
(3, 'Dairy', 'Fresh whole milk, cheese, yogurt, butter, ghee and dairy products.', 'water_drop', '#3B82F6', 'active'),
(4, 'Spices', 'Whole spices, ground seasonings, salt, pepper, turmeric and masala mixes.', 'whatshot', '#EF4444', 'active'),
(5, 'Oils', 'Cold-pressed sunflower oil, olive oil, mustard oil, sesame oil and cooking fats.', 'opacity', '#EAB308', 'active'),
(6, 'Snacks & Packaged Foods', 'Biscuits, crackers, instant noodles, chips, pasta and breakfast cereals.', 'fastfood', '#8B5CF6', 'active'),
(7, 'Beverages', 'Loose tea leaves, filter coffee powder, herbal infusions and beverages.', 'coffee', '#06B6D4', 'active'),
(8, 'Other Groceries', 'General pantry groceries, dry staples, condiments and cooking essentials.', 'category', '#64748B', 'active')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`);

-- 3. Initial Smart Recipes
INSERT INTO `recipes` (`id`, `title`, `category_id`, `description`, `image_url`, `youtube_id`, `youtube_url`, `prep_time`, `difficulty`, `calories`, `instructions`, `status`) VALUES
(1, 'Aromatic Tadka Dal & Basmati Rice', 1, 'Comforting yellow lentils tempered with cumin, turmeric, and pure ghee served alongside fluffy basmati rice.', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=600&q=80', 'DAP33YtKmgw', 'https://www.youtube.com/watch?v=DAP33YtKmgw', '20 mins', 'Easy', 340, '1. Rinse basmati rice and red lentils under cold water until clear.\n2. Simmer red lentils with turmeric powder and salt until tender and creamy.\n3. In a small pan, heat pure ghee and sizzle cumin until aromatic.\n4. Pour the hot spiced ghee tadka over the dal and serve hot with steamed basmati rice.', 'published'),
(2, 'Artisan Toasted Sourdough with Olive Oil', 2, 'Crispy golden toasted sourdough slices drizzled with cold-pressed olive oil, cracked black pepper, and sea salt.', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80', 'fFq2sL_Ea_Y', 'https://www.youtube.com/watch?v=fFq2sL_Ea_Y', '8 mins', 'Easy', 210, '1. Thickly slice the sourdough bread into hearty pieces.\n2. Toast in a pan or toaster until golden and crunchy on the crust.\n3. Generously drizzle with cold-pressed olive oil while still warm.\n4. Finish with freshly cracked black pepper and a pinch of salt.', 'published'),
(3, 'Classic Aglio e Olio Penne Pasta', 6, 'Simple Italian pantry pasta tossed with fragrant olive oil, black pepper, and sea salt.', 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=600&q=80', 'bJUiWdM__Qw', 'https://www.youtube.com/watch?v=bJUiWdM__Qw', '15 mins', 'Easy', 380, '1. Bring a pot of well-salted water to a boil and cook penne until al dente.\n2. Reserve 1/4 cup of starchy pasta water before draining.\n3. Gently warm olive oil and black pepper in a large pan.\n4. Toss pasta into the oil with reserved water until glossy and emulsified.', 'published'),
(4, 'Spiced Warm Chai & Digestive Biscuits', 7, 'Rich freshly brewed tea with creamy whole milk and cane sugar, served with crisp digestive biscuits.', 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80', '2O93N6xL2eQ', 'https://www.youtube.com/watch?v=2O93N6xL2eQ', '10 mins', 'Easy', 160, '1. Bring 1 cup of water to a boil with crushed cardamom.\n2. Add strong tea leaves and simmer for 2 minutes.\n3. Pour in whole milk and sugar, bringing to a rolling boil.\n4. Strain through a fine mesh sieve into mugs and serve with biscuits.', 'published')
ON DUPLICATE KEY UPDATE `title` = VALUES(`title`);

-- 4. Initial Recipe Ingredients
INSERT INTO `recipe_ingredients` (`id`, `recipe_id`, `ingredient_name`, `quantity`, `unit`, `is_required`) VALUES
(1, 1, 'Basmati Rice', '1', 'cup', 1),
(2, 1, 'Red Lentils', '1', 'cup', 1),
(3, 1, 'Turmeric Powder', '0.5', 'tsp', 1),
(4, 1, 'Cumin', '1', 'tsp', 1),
(5, 1, 'Pure Ghee', '2', 'tbsp', 1),
(6, 1, 'Salt', '1', 'tsp', 1),
(7, 2, 'Sourdough Bread', '2', 'slices', 1),
(8, 2, 'Olive Oil', '2', 'tbsp', 1),
(9, 2, 'Salt', '1', 'pinch', 1),
(10, 2, 'Black Pepper', '0.5', 'tsp', 1),
(11, 3, 'Pasta', '200', 'grams', 1),
(12, 3, 'Olive Oil', '3', 'tbsp', 1),
(13, 3, 'Black Pepper', '1', 'tsp', 1),
(14, 3, 'Salt', '1', 'tsp', 1),
(15, 3, 'Garlic', '3', 'cloves', 0),
(16, 4, 'Tea Leaves', '2', 'tsp', 1),
(17, 4, 'Whole Milk', '0.5', 'cup', 1),
(18, 4, 'Sugar', '2', 'tsp', 1),
(19, 4, 'Digestive Biscuits', '4', 'pieces', 0)
ON DUPLICATE KEY UPDATE `ingredient_name` = VALUES(`ingredient_name`);

-- 5. Initial Announcements
INSERT INTO `announcements` (`id`, `title`, `message`, `image_url`, `status`, `start_date`, `end_date`) VALUES
(1, 'Welcome to Home Pantry!', 'Keep track of your grocery inventory, minimize food waste, and get smart recipe suggestions right from your pantry.', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80', 'published', '2026-01-01', '2026-12-31')
ON DUPLICATE KEY UPDATE `title` = VALUES(`title`);

-- 6. Initial App Settings
INSERT INTO `app_settings` (`id`, `setting_key`, `setting_value`, `description`) VALUES
(1, 'app_name', 'Home Pantry', 'Display application name'),
(2, 'admin_email', 'admin@homepantry.com', 'Primary system contact email'),
(3, 'default_currency', '₹', 'Currency symbol for grocery inventory'),
(4, 'expiry_warning_days', '2', 'Days before expiry to trigger urgent alert')
ON DUPLICATE KEY UPDATE `setting_value` = VALUES(`setting_value`);
