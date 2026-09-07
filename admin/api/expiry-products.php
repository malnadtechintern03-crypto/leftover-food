<?php
/**
 * REST API - Expiry Alerts & Categorized Products Endpoint
 * GET /api/expiry-products.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only GET is supported.'], 405);
}

try {
    $db = Database::getConnection();

    $sql = "SELECT p.*,
            CASE 
                WHEN p.expiry_date IS NULL THEN NULL 
                ELSE DATEDIFF(p.expiry_date, CURDATE()) 
            END AS days_remaining
            FROM products p
            WHERE p.is_consumed = 0
            ORDER BY p.expiry_date IS NULL ASC, p.expiry_date ASC, p.name ASC";

    $stmt = $db->query($sql);
    $products = $stmt->fetchAll();

    $expired = [];
    $expiringToday = [];
    $within7Days = [];
    $within30Days = [];
    $noExpiry = [];

    foreach ($products as $p) {
        $p['reminder_enabled'] = (bool)$p['reminder_enabled'];
        $p['is_consumed'] = (bool)$p['is_consumed'];
        $p['quantity'] = (float)$p['quantity'];
        $p['purchase_price'] = $p['purchase_price'] !== null ? (float)$p['purchase_price'] : 0.0;

        if ($p['expiry_date'] === null) {
            $p['expiry_status'] = 'No Expiry Date';
            $noExpiry[] = $p;
            continue;
        }

        $days = (int)$p['days_remaining'];
        if ($days < 0) {
            $p['expiry_status'] = 'Expired';
            $expired[] = $p;
        } elseif ($days === 0) {
            $p['expiry_status'] = 'Expiring Today';
            $expiringToday[] = $p;
        } elseif ($days > 0 && $days <= 7) {
            $p['expiry_status'] = 'Expiring Soon';
            $within7Days[] = $p;
        } elseif ($days > 7 && $days <= 30) {
            $p['expiry_status'] = 'Safe';
            $within30Days[] = $p;
        } else {
            $p['expiry_status'] = 'Safe';
        }
    }

    json_response([
        'status' => 'success',
        'counts' => [
            'total_active' => count($products),
            'expired' => count($expired),
            'expiring_today' => count($expiringToday),
            'within_7_days' => count($within7Days),
            'within_30_days' => count($within30Days),
            'no_expiry' => count($noExpiry),
        ],
        'sections' => [
            'expired' => $expired,
            'expiring_today' => $expiringToday,
            'within_7_days' => $within7Days,
            'within_30_days' => $within30Days,
            'no_expiry' => $noExpiry,
        ],
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to fetch expiry alerts: ' . $e->getMessage(),
    ], 500);
}
