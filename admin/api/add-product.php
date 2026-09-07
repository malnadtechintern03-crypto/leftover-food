<?php
/**
 * REST API - Add Product Endpoint
 * POST /api/add-product.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only POST is supported.'], 405);
}

// Read JSON input or fallback to $_POST
$raw = file_get_contents('php://input');
$input = !empty($raw) ? json_decode($raw, true) : $_POST;

if (!is_array($input) || empty(trim($input['name'] ?? ''))) {
    json_response(['status' => 'error', 'message' => 'Product name is required.'], 400);
}

try {
    $db = Database::getConnection();

    $id = !empty($input['id']) ? trim((string)$input['id']) : bin2hex(random_bytes(16));
    $userId = !empty($input['user_id']) ? trim((string)$input['user_id']) : 'default_user';
    $name = trim((string)$input['name']);
    $brand = !empty($input['brand']) ? trim((string)$input['brand']) : null;
    $barcode = !empty($input['barcode']) ? trim((string)$input['barcode']) : null;
    $imagePath = !empty($input['image_path']) ? trim((string)$input['image_path']) : null;
    $category = !empty($input['category']) ? trim((string)$input['category']) : 'Other Products';
    $subcategory = !empty($input['subcategory']) ? trim((string)$input['subcategory']) : null;
    $quantity = isset($input['quantity']) ? (float)$input['quantity'] : 1.0;
    $unit = !empty($input['unit']) ? trim((string)$input['unit']) : 'pieces';
    $purchasePrice = isset($input['purchase_price']) && $input['purchase_price'] !== '' ? (float)$input['purchase_price'] : null;
    $purchaseDate = !empty($input['purchase_date']) ? date('Y-m-d', strtotime((string)$input['purchase_date'])) : date('Y-m-d');
    $manufacturingDate = !empty($input['manufacturing_date']) ? date('Y-m-d', strtotime((string)$input['manufacturing_date'])) : null;
    $expiryDate = !empty($input['expiry_date']) ? date('Y-m-d', strtotime((string)$input['expiry_date'])) : null;
    $reminderDate = !empty($input['reminder_date']) ? date('Y-m-d H:i:s', strtotime((string)$input['reminder_date'])) : null;
    $reminderEnabled = isset($input['reminder_enabled']) ? (int)(bool)$input['reminder_enabled'] : 1;
    $reminderDaysBefore = isset($input['reminder_days_before']) ? (string)$input['reminder_days_before'] : '7';
    $notificationId = isset($input['notification_id']) ? (int)$input['notification_id'] : abs(crc32($id));
    $storageLocation = !empty($input['storage_location']) ? trim((string)$input['storage_location']) : 'pantry';
    $notes = !empty($input['notes']) ? trim((string)$input['notes']) : null;

    // Calculate expiry status
    $expiryStatus = 'No Expiry Date';
    if ($expiryDate !== null) {
        $today = new DateTime('today');
        $exp = new DateTime($expiryDate);
        $diff = (int)$today->diff($exp)->format('%r%a');
        if ($diff < 0) {
            $expiryStatus = 'Expired';
        } elseif ($diff <= 2) {
            $expiryStatus = 'Expiring Soon';
        } else {
            $expiryStatus = 'Safe';
        }
    }

    $sql = "INSERT INTO products (
        id, user_id, name, brand, barcode, image_path, category, subcategory,
        quantity, unit, purchase_price, purchase_date, manufacturing_date,
        expiry_date, reminder_date, reminder_enabled, reminder_days_before,
        notification_id, expiry_status, storage_location, notes, is_consumed
    ) VALUES (
        ?, ?, ?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?, 0
    ) ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        brand = VALUES(brand),
        barcode = VALUES(barcode),
        image_path = VALUES(image_path),
        category = VALUES(category),
        subcategory = VALUES(subcategory),
        quantity = VALUES(quantity),
        unit = VALUES(unit),
        purchase_price = VALUES(purchase_price),
        purchase_date = VALUES(purchase_date),
        manufacturing_date = VALUES(manufacturing_date),
        expiry_date = VALUES(expiry_date),
        reminder_date = VALUES(reminder_date),
        reminder_enabled = VALUES(reminder_enabled),
        reminder_days_before = VALUES(reminder_days_before),
        expiry_status = VALUES(expiry_status),
        storage_location = VALUES(storage_location),
        notes = VALUES(notes)";

    $stmt = $db->prepare($sql);
    $stmt->execute([
        $id, $userId, $name, $brand, $barcode, $imagePath, $category, $subcategory,
        $quantity, $unit, $purchasePrice, $purchaseDate, $manufacturingDate,
        $expiryDate, $reminderDate, $reminderEnabled, $reminderDaysBefore,
        $notificationId, $expiryStatus, $storageLocation, $notes
    ]);

    // Insert reminder records if enabled and expiryDate exists
    if ($reminderEnabled && $expiryDate !== null) {
        // Clear previous reminders for this product
        $db->prepare("DELETE FROM product_reminders WHERE product_id = ?")->execute([$id]);

        $daysList = array_filter(array_map('trim', explode(',', $reminderDaysBefore)), fn($v) => is_numeric($v));
        $insRem = $db->prepare("INSERT INTO product_reminders (
            user_id, product_id, reminder_date, days_before_expiry, notification_id, is_sent, is_enabled
        ) VALUES (?, ?, ?, ?, ?, 0, 1)");

        foreach ($daysList as $d) {
            $daysInt = (int)$d;
            $remTime = date('Y-m-d 09:00:00', strtotime("{$expiryDate} -{$daysInt} days"));
            $notifSubId = abs(($notificationId * 31 + $daysInt) % 100000000);
            $insRem->execute([$userId, $id, $remTime, $daysInt, $notifSubId]);
        }

        if ($reminderDate !== null) {
            $insRem->execute([$userId, $id, $reminderDate, 0, abs(($notificationId * 31 + 999) % 100000000)]);
        }
    }

    json_response([
        'status' => 'success',
        'message' => 'Product saved successfully.',
        'data' => [
            'id' => $id,
            'name' => $name,
            'expiry_status' => $expiryStatus,
        ],
    ], 201);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to save product: ' . $e->getMessage(),
    ], 500);
}
