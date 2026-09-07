<?php
/**
 * REST API - Single Product Details Endpoint
 * GET /api/product-details.php?id=...
 * GET /api/product-details.php?barcode=...
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only GET is supported.'], 405);
}

$id = isset($_GET['id']) ? trim((string)$_GET['id']) : '';
$barcode = isset($_GET['barcode']) ? trim((string)$_GET['barcode']) : '';

if ($id === '' && $barcode === '') {
    json_response(['status' => 'error', 'message' => 'Product id or barcode is required.'], 400);
}

try {
    $db = Database::getConnection();

    if ($id !== '') {
        $stmt = $db->prepare("SELECT p.*,
            CASE 
                WHEN p.expiry_date IS NULL THEN NULL 
                ELSE DATEDIFF(p.expiry_date, CURDATE()) 
            END AS days_remaining
            FROM products p WHERE p.id = ? LIMIT 1");
        $stmt->execute([$id]);
    } else {
        $stmt = $db->prepare("SELECT p.*,
            CASE 
                WHEN p.expiry_date IS NULL THEN NULL 
                ELSE DATEDIFF(p.expiry_date, CURDATE()) 
            END AS days_remaining
            FROM products p WHERE p.barcode = ? LIMIT 1");
        $stmt->execute([$barcode]);
    }

    $product = $stmt->fetch();

    if (!$product) {
        json_response(['status' => 'error', 'message' => 'Product not found.'], 404);
    }

    $product['reminder_enabled'] = (bool)$product['reminder_enabled'];
    $product['is_consumed'] = (bool)$product['is_consumed'];
    $product['is_favorite'] = (bool)$product['is_favorite'];
    $product['quantity'] = (float)$product['quantity'];
    $product['purchase_price'] = $product['purchase_price'] !== null ? (float)$product['purchase_price'] : 0.0;

    // Fetch associated reminders
    $remStmt = $db->prepare("SELECT * FROM product_reminders WHERE product_id = ? ORDER BY reminder_date ASC");
    $remStmt->execute([$product['id']]);
    $product['reminders'] = $remStmt->fetchAll();

    json_response([
        'status' => 'success',
        'data' => $product,
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to fetch product details: ' . $e->getMessage(),
    ], 500);
}
