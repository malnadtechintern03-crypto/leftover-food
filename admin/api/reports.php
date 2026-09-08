<?php
/**
 * REST API - Reports & Analytics Telemetry Endpoint
 * GET /api/reports.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

try {
    $db = Database::getConnection();

    $userId = trim((string)($_GET['user_id'] ?? ''));
    $userFilter = $userId !== '' ? " AND user_id = " . $db->quote($userId) : "";

    $totalProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' {$userFilter}")->fetchColumn();
    $expired = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date < CURDATE() {$userFilter}")->fetchColumn();
    $expiringSoon = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date >= CURDATE() AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY) {$userFilter}")->fetchColumn();
    $safe = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date > DATE_ADD(CURDATE(), INTERVAL 7 DAY) {$userFilter}")->fetchColumn();
    $totalValue = (float)$db->query("SELECT SUM(quantity * COALESCE(purchase_price, 0)) FROM products WHERE status != 'Archived' {$userFilter}")->fetchColumn();

    $categories = $db->query("
        SELECT category, COUNT(*) as count
        FROM products
        WHERE status != 'Archived' {$userFilter}
        GROUP BY category
        ORDER BY count DESC
    ")->fetchAll();

    json_response([
        'status' => 'success',
        'data' => [
            'total_products' => $totalProducts,
            'expired' => $expired,
            'expiring_soon' => $expiringSoon,
            'safe' => $safe,
            'total_estimated_value' => round($totalValue, 2),
            'categories' => $categories,
        ]
    ]);
} catch (Throwable $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
