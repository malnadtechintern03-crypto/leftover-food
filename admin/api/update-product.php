<?php
/**
 * REST API - Update Product Endpoint
 * POST / PUT /api/update-product.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'POST' && $method !== 'PUT') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Use POST or PUT.'], 405);
}

$raw = file_get_contents('php://input');
$input = !empty($raw) ? json_decode($raw, true) : $_POST;

if (!is_array($input) || empty(trim((string)($input['id'] ?? '')))) {
    json_response(['status' => 'error', 'message' => 'Product ID is required for update.'], 400);
}

$id = trim((string)$input['id']);

try {
    $db = Database::getConnection();

    // Check if product exists
    $chk = $db->prepare("SELECT * FROM products WHERE id = ? LIMIT 1");
    $chk->execute([$id]);
    $current = $chk->fetch();

    if (!$current) {
        json_response(['status' => 'error', 'message' => 'Product not found.'], 404);
    }

    $name = isset($input['name']) ? trim((string)$input['name']) : $current['name'];
    $brand = array_key_exists('brand', $input) ? ($input['brand'] ? trim((string)$input['brand']) : null) : $current['brand'];
    $barcode = array_key_exists('barcode', $input) ? ($input['barcode'] ? trim((string)$input['barcode']) : null) : $current['barcode'];
    $imagePath = array_key_exists('image_path', $input) ? ($input['image_path'] ? trim((string)$input['image_path']) : null) : $current['image_path'];
    $category = isset($input['category']) ? trim((string)$input['category']) : $current['category'];
    $subcategory = array_key_exists('subcategory', $input) ? ($input['subcategory'] ? trim((string)$input['subcategory']) : null) : $current['subcategory'];
    $quantity = isset($input['quantity']) ? (float)$input['quantity'] : (float)$current['quantity'];
    $unit = isset($input['unit']) ? trim((string)$input['unit']) : $current['unit'];
    $purchasePrice = array_key_exists('purchase_price', $input) ? ($input['purchase_price'] !== null && $input['purchase_price'] !== '' ? (float)$input['purchase_price'] : null) : $current['purchase_price'];
    $purchaseDate = isset($input['purchase_date']) ? date('Y-m-d', strtotime((string)$input['purchase_date'])) : $current['purchase_date'];
    $manufacturingDate = array_key_exists('manufacturing_date', $input) ? ($input['manufacturing_date'] ? date('Y-m-d', strtotime((string)$input['manufacturing_date'])) : null) : $current['manufacturing_date'];
    $expiryDate = array_key_exists('expiry_date', $input) ? ($input['expiry_date'] ? date('Y-m-d', strtotime((string)$input['expiry_date'])) : null) : $current['expiry_date'];
    $reminderDate = array_key_exists('reminder_date', $input) ? ($input['reminder_date'] ? date('Y-m-d H:i:s', strtotime((string)$input['reminder_date'])) : null) : $current['reminder_date'];
    $reminderEnabled = isset($input['reminder_enabled']) ? (int)(bool)$input['reminder_enabled'] : (int)$current['reminder_enabled'];
    $reminderDaysBefore = isset($input['reminder_days_before']) ? (string)$input['reminder_days_before'] : $current['reminder_days_before'];
    $storageLocation = isset($input['storage_location']) ? trim((string)$input['storage_location']) : $current['storage_location'];
    $notes = array_key_exists('notes', $input) ? ($input['notes'] ? trim((string)$input['notes']) : null) : $current['notes'];
    $isConsumed = isset($input['is_consumed']) ? (int)(bool)$input['is_consumed'] : (int)$current['is_consumed'];

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

    $sql = "UPDATE products SET
        name = ?, brand = ?, barcode = ?, image_path = ?, category = ?, subcategory = ?,
        quantity = ?, unit = ?, purchase_price = ?, purchase_date = ?, manufacturing_date = ?,
        expiry_date = ?, reminder_date = ?, reminder_enabled = ?, reminder_days_before = ?,
        expiry_status = ?, storage_location = ?, notes = ?, is_consumed = ?
        WHERE id = ?";

    $stmt = $db->prepare($sql);
    $stmt->execute([
        $name, $brand, $barcode, $imagePath, $category, $subcategory,
        $quantity, $unit, $purchasePrice, $purchaseDate, $manufacturingDate,
        $expiryDate, $reminderDate, $reminderEnabled, $reminderDaysBefore,
        $expiryStatus, $storageLocation, $notes, $isConsumed, $id
    ]);

    // Reschedule or clear reminders
    $db->prepare("DELETE FROM product_reminders WHERE product_id = ?")->execute([$id]);

    if ($reminderEnabled && $expiryDate !== null && !$isConsumed) {
        $notificationId = (int)$current['notification_id'];
        $userId = $current['user_id'];
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
        'message' => 'Product updated successfully.',
        'data' => [
            'id' => $id,
            'name' => $name,
            'expiry_date' => $expiryDate,
            'expiry_status' => $expiryStatus,
        ],
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to update product: ' . $e->getMessage(),
    ], 500);
}
