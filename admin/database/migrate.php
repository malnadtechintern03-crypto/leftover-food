<?php
/**
 * ScanSmart Database Auto-Migrator
 * Safely adds any missing tables, columns, indexes, and seed records
 * without dropping or modifying existing records.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

try {
    $db = Database::getConnection();
    $messages = [];

    // 1. Create tables if not existing
    $sqlFile = __DIR__ . '/admin_panel.sql';
    if (file_exists($sqlFile)) {
        $sql = file_get_contents($sqlFile);
        // Remove comments and execute statements
        $statements = array_filter(array_map('trim', explode(';', $sql)));
        foreach ($statements as $stmt) {
            if (empty($stmt)) continue;
            // Skip USE and CREATE DATABASE in hosting environments where DB is pre-assigned
            if (stripos($stmt, 'CREATE DATABASE') === 0 || stripos($stmt, 'USE `') === 0) {
                continue;
            }
            try {
                $db->exec($stmt);
            } catch (PDOException $e) {
                // Table/column might already exist, continue
            }
        }
        $messages[] = "Base schema tables checked and updated.";
    }

    // 2. Dynamically check and add any missing columns in `products` table
    $productCols = [
        'qr_code' => 'VARCHAR(255) NULL AFTER `barcode`',
        'category_id' => 'INT NULL AFTER `category`',
        'subcategory_id' => 'INT NULL AFTER `subcategory`',
        'description' => 'TEXT NULL AFTER `subcategory_id`',
        'currency' => "VARCHAR(10) NOT NULL DEFAULT '₹' AFTER `purchase_price`",
        'manufacturer' => 'VARCHAR(150) NULL AFTER `storage_location`',
        'country_of_origin' => 'VARCHAR(100) NULL AFTER `manufacturer`',
        'ingredients' => 'TEXT NULL AFTER `country_of_origin`',
        'usage_instructions' => 'TEXT NULL AFTER `ingredients`',
        'warranty_information' => 'VARCHAR(255) NULL AFTER `usage_instructions`',
        'product_url' => 'VARCHAR(500) NULL AFTER `warranty_information`',
        'source' => "VARCHAR(50) NOT NULL DEFAULT 'Manual Entry' AFTER `product_url`",
        'category_confidence' => 'INT NOT NULL DEFAULT 100 AFTER `source`',
        'review_status' => "ENUM('Approved', 'Pending Review', 'Rejected', 'Needs Correction') NOT NULL DEFAULT 'Approved' AFTER `category_confidence`",
        'status' => "ENUM('Active', 'Inactive', 'Pending Review', 'Needs Review', 'Archived') NOT NULL DEFAULT 'Active' AFTER `review_status`",
    ];

    $existingCols = [];
    $stmt = $db->query("SHOW COLUMNS FROM products");
    while ($row = $stmt->fetch()) {
        $existingCols[] = strtolower($row['Field']);
    }

    foreach ($productCols as $col => $definition) {
        if (!in_array(strtolower($col), $existingCols, true)) {
            try {
                $db->exec("ALTER TABLE `products` ADD COLUMN `{$col}` {$definition}");
                $messages[] = "Added column `products`.`{$col}`";
            } catch (PDOException $e) {
                // Skip if exists
            }
        }
    }

    // 2b. Dynamically check and add missing columns in `categories` table
    $catCols = [
        'sort_order' => 'INT NOT NULL DEFAULT 0 AFTER `status`',
        'image_url' => 'TEXT NULL AFTER `sort_order`',
    ];
    $existingCatCols = [];
    $stmt = $db->query("SHOW COLUMNS FROM categories");
    while ($row = $stmt->fetch()) {
        $existingCatCols[] = strtolower($row['Field']);
    }
    foreach ($catCols as $col => $definition) {
        if (!in_array(strtolower($col), $existingCatCols, true)) {
            try {
                $db->exec("ALTER TABLE `categories` ADD COLUMN `{$col}` {$definition}");
                $messages[] = "Added column `categories`.`{$col}`";
            } catch (PDOException $e) {
                // Skip if exists
            }
        }
    }

    // 2c. Dynamically check and add missing columns in `product_reminders` table
    $remCols = [
        'last_sent_at' => 'DATETIME NULL AFTER `is_sent`',
    ];
    $existingRemCols = [];
    $stmt = $db->query("SHOW COLUMNS FROM product_reminders");
    while ($row = $stmt->fetch()) {
        $existingRemCols[] = strtolower($row['Field']);
    }
    foreach ($remCols as $col => $definition) {
        if (!in_array(strtolower($col), $existingRemCols, true)) {
            try {
                $db->exec("ALTER TABLE `product_reminders` ADD COLUMN `{$col}` {$definition}");
                $messages[] = "Added column `product_reminders`.`{$col}`";
            } catch (PDOException $e) {
                // Skip if exists
            }
        }
    }

    // 3. Ensure role enum in `admins` table includes 'editor' and 'viewer'
    try {
        $db->exec("ALTER TABLE `admins` MODIFY COLUMN `role` ENUM('super_admin', 'admin', 'editor', 'viewer') NOT NULL DEFAULT 'admin'");
        $messages[] = "Updated `admins`.`role` enum definition.";
    } catch (PDOException $e) {
        // Continue
    }

    // 4. Ensure admin_activity_logs exists
    $db->exec("CREATE TABLE IF NOT EXISTS `admin_activity_logs` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `admin_id` INT NULL,
        `admin_name` VARCHAR(100) NULL,
        `action` VARCHAR(100) NOT NULL,
        `description` TEXT NOT NULL,
        `ip_address` VARCHAR(45) NULL,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX `idx_logs_admin` (`admin_id`),
        INDEX `idx_logs_date` (`created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    // 5. Ensure users table exists with password column and seed demo user
    $db->exec("CREATE TABLE IF NOT EXISTS `users` (
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
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    // Check if password column exists in users table
    $userCols = [];
    $stmt = $db->query("SHOW COLUMNS FROM users");
    while ($row = $stmt->fetch()) {
        $userCols[] = strtolower($row['Field']);
    }
    if (!in_array('password', $userCols, true)) {
        try {
            $db->exec("ALTER TABLE `users` ADD COLUMN `password` VARCHAR(255) NULL AFTER `email`");
            $messages[] = "Added column `users`.`password`";
        } catch (PDOException $e) {
            // Ignore if already added
        }
    }

    // Seed or update Demo User (user@homepantry.com / user123)
    $demoPasswordHash = password_hash('user123', PASSWORD_BCRYPT);
    $checkDemo = $db->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
    $checkDemo->execute(['user@homepantry.com']);
    if (!$checkDemo->fetch()) {
        $insertDemo = $db->prepare("
            INSERT INTO users (id, name, email, password, role, status)
            VALUES (?, ?, ?, ?, 'user', 'active')
        ");
        $insertDemo->execute(['user_demo_chef', 'Demo Chef', 'user@homepantry.com', $demoPasswordHash]);
        $messages[] = "Created demo user account (user@homepantry.com / user123)";
    }


    // Output result
    if (php_sapi_name() === 'cli') {
        echo "Migration completed successfully!\n";
        foreach ($messages as $msg) {
            echo " - {$msg}\n";
        }
    } else {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'status' => 'success',
            'message' => 'Database migration completed successfully.',
            'details' => $messages,
        ], JSON_PRETTY_PRINT);
    }
} catch (Throwable $e) {
    if (php_sapi_name() === 'cli') {
        echo "Migration failed: " . $e->getMessage() . "\n";
    } else {
        header('Content-Type: application/json; charset=utf-8', true, 500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Migration failed: ' . $e->getMessage(),
        ]);
    }
}
