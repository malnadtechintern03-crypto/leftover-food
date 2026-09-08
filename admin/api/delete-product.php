<?php
/**
 * REST API - Delete Product Inventory Item Endpoint
 * Accepts DELETE or POST requests from Mobile Application Sync Queue
 * URL: /api/delete-product.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($method !== 'POST' && $method !== 'DELETE') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Use POST or DELETE.'], 405);
}

$raw = file_get_contents('php://input');
$input = !empty($raw) ? json_decode($raw, true) : $_POST;
if (!is_array($input)) {
    $input = [];
}

$id = isset($_GET['id']) ? trim((string)$_GET['id']) : (!empty($input['id']) ? trim((string)$input['id']) : null);
$productId = isset($_GET['product_id']) ? trim((string)$_GET['product_id']) : (!empty($input['product_id']) ? trim((string)$input['product_id']) : null);

$targetId = $id ?? $productId;

if ($targetId === null || $targetId === '') {
    json_response(['status' => 'error', 'message' => 'Either id or product_id is required.'], 400);
}

try {
    $db = Database::getConnection();

    // Check if item exists
    $checkStmt = $db->prepare("SELECT id, name FROM products WHERE id = ? LIMIT 1");
    $checkStmt->execute([$targetId]);
    $existing = $checkStmt->fetch();

    if (!$existing) {
        // Idempotent: already deleted
        json_response([
            'status' => 'success',
            'message' => "Product already deleted or does not exist.",
            'deleted_id' => $targetId,
            'deleted_count' => 0,
        ]);
    }

    // Delete related reminders first (in case foreign key cascade is disabled)
    $db->prepare("DELETE FROM product_reminders WHERE product_id = ?")->execute([$targetId]);

    // Delete product
    $delStmt = $db->prepare("DELETE FROM products WHERE id = ?");
    $delStmt->execute([$targetId]);
    $deleted = $delStmt->rowCount();

    json_response([
        'status' => 'success',
        'message' => "Product '{$existing['name']}' deleted successfully from database.",
        'deleted_id' => $targetId,
        'deleted_count' => $deleted,
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to delete product: ' . $e->getMessage(),
    ], 500);
}
