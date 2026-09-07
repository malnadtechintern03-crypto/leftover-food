<?php
/**
 * REST API - Product Reminders Endpoint
 * GET /api/reminders.php
 * GET /api/reminders.php?product_id=...
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only GET is supported.'], 405);
}

$productId = isset($_GET['product_id']) ? trim((string)$_GET['product_id']) : null;
$onlyPending = isset($_GET['pending']) && $_GET['pending'] === '1';

try {
    $db = Database::getConnection();

    $where = ['r.is_enabled = 1', 'p.is_consumed = 0'];
    $params = [];

    if ($productId !== null && $productId !== '') {
        $where[] = 'r.product_id = ?';
        $params[] = $productId;
    }

    if ($onlyPending) {
        $where[] = 'r.is_sent = 0';
    }

    $whereClause = 'WHERE ' . implode(' AND ', $where);

    $sql = "SELECT r.*, p.name AS product_name, p.brand AS product_brand, 
            p.category AS product_category, p.expiry_date, p.barcode
            FROM product_reminders r
            JOIN products p ON r.product_id = p.id
            {$whereClause}
            ORDER BY r.reminder_date ASC";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $reminders = $stmt->fetchAll();

    $formatted = array_map(function ($r) {
        $r['is_sent'] = (bool)$r['is_sent'];
        $r['is_enabled'] = (bool)$r['is_enabled'];
        $r['days_before_expiry'] = (int)$r['days_before_expiry'];
        $r['notification_id'] = (int)$r['notification_id'];
        return $r;
    }, $reminders);

    json_response([
        'status' => 'success',
        'count' => count($formatted),
        'data' => $formatted,
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to fetch reminders: ' . $e->getMessage(),
    ], 500);
}
