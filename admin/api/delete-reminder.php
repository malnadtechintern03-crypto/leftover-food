<?php
/**
 * REST API - Delete Product Reminder Endpoint
 * POST / DELETE /api/delete-reminder.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'POST' && $method !== 'DELETE') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Use POST or DELETE.'], 405);
}

$raw = file_get_contents('php://input');
$input = !empty($raw) ? json_decode($raw, true) : $_POST;

$id = isset($_GET['id']) ? (int)$_GET['id'] : (!empty($input['id']) ? (int)$input['id'] : null);
$productId = isset($_GET['product_id']) ? trim((string)$_GET['product_id']) : (!empty($input['product_id']) ? trim((string)$input['product_id']) : null);

if ($id === null && ($productId === null || $productId === '')) {
    json_response(['status' => 'error', 'message' => 'Either id or product_id is required.'], 400);
}

try {
    $db = Database::getConnection();

    if ($id !== null) {
        $stmt = $db->prepare("DELETE FROM product_reminders WHERE id = ?");
        $stmt->execute([$id]);
        $deleted = $stmt->rowCount();
    } else {
        $stmt = $db->prepare("DELETE FROM product_reminders WHERE product_id = ?");
        $stmt->execute([$productId]);
        $deleted = $stmt->rowCount();

        // Also update product reminder_enabled = 0
        $db->prepare("UPDATE products SET reminder_enabled = 0 WHERE id = ?")->execute([$productId]);
    }

    json_response([
        'status' => 'success',
        'message' => "Deleted {$deleted} reminder(s).",
        'deleted_count' => $deleted,
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to delete reminder: ' . $e->getMessage(),
    ], 500);
}
