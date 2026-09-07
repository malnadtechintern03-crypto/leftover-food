<?php
/**
 * REST API - Save Product Reminder Endpoint
 * POST /api/save-reminder.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only POST is supported.'], 405);
}

$raw = file_get_contents('php://input');
$input = !empty($raw) ? json_decode($raw, true) : $_POST;

if (!is_array($input) || empty($input['product_id']) || empty($input['reminder_date'])) {
    json_response(['status' => 'error', 'message' => 'product_id and reminder_date are required.'], 400);
}

$productId = trim((string)$input['product_id']);
$reminderDate = date('Y-m-d H:i:s', strtotime((string)$input['reminder_date']));
$daysBeforeExpiry = isset($input['days_before_expiry']) ? (int)$input['days_before_expiry'] : 0;
$notificationId = isset($input['notification_id']) ? (int)$input['notification_id'] : abs(crc32($productId . $reminderDate));
$userId = !empty($input['user_id']) ? trim((string)$input['user_id']) : 'default_user';

try {
    $db = Database::getConnection();

    // Verify product exists
    $chk = $db->prepare("SELECT id FROM products WHERE id = ?");
    $chk->execute([$productId]);
    if (!$chk->fetch()) {
        json_response(['status' => 'error', 'message' => 'Product not found.'], 404);
    }

    $stmt = $db->prepare("INSERT INTO product_reminders (
        user_id, product_id, reminder_date, days_before_expiry, notification_id, is_sent, is_enabled
    ) VALUES (?, ?, ?, ?, ?, 0, 1)");

    $stmt->execute([$userId, $productId, $reminderDate, $daysBeforeExpiry, $notificationId]);
    $newId = (int)$db->lastInsertId();

    // Ensure product reminder_enabled is 1
    $db->prepare("UPDATE products SET reminder_enabled = 1 WHERE id = ?")->execute([$productId]);

    json_response([
        'status' => 'success',
        'message' => 'Reminder created successfully.',
        'data' => [
            'id' => $newId,
            'product_id' => $productId,
            'reminder_date' => $reminderDate,
            'days_before_expiry' => $daysBeforeExpiry,
            'notification_id' => $notificationId,
        ],
    ], 201);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to save reminder: ' . $e->getMessage(),
    ], 500);
}
