<?php
/**
 * REST API - Scan History Logging Endpoint
 * POST /api/scan-history.php (Record scan event)
 * GET /api/scan-history.php (List scans for a user)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    json_response(['status' => 'ok'], 200);
}

try {
    $db = Database::getConnection();

    if ($method === 'POST') {
        $raw = file_get_contents('php://input');
        $input = !empty($raw) ? json_decode($raw, true) : $_POST;

        $userId = !empty($input['user_id']) ? trim((string)$input['user_id']) : 'default_user';
        $barcode = !empty($input['barcode']) ? trim((string)$input['barcode']) : null;
        $scanType = !empty($input['scan_type']) ? trim((string)$input['scan_type']) : 'Barcode';
        $productFound = isset($input['product_found']) ? (int)(bool)$input['product_found'] : 1;
        $productId = !empty($input['product_id']) ? trim((string)$input['product_id']) : null;
        $productName = !empty($input['product_name']) ? trim((string)$input['product_name']) : null;
        $scanResult = !empty($input['scan_result']) ? trim((string)$input['scan_result']) : null;

        $stmt = $db->prepare("
            INSERT INTO scan_history (user_id, barcode, scan_type, product_found, product_id, product_name, scan_result, scan_date, scan_time)
            VALUES (?, ?, ?, ?, ?, ?, ?, CURDATE(), CURTIME())
        ");
        $stmt->execute([$userId, $barcode, $scanType, $productFound, $productId, $productName, $scanResult]);

        // Increment scan count on user profile
        $db->prepare("UPDATE users SET scans_count = scans_count + 1 WHERE id = ?")->execute([$userId]);

        json_response(['status' => 'success', 'message' => 'Scan recorded successfully.'], 201);
    }

    if ($method === 'GET') {
        $userId = trim((string)($_GET['user_id'] ?? 'default_user'));
        $stmt = $db->prepare("SELECT * FROM scan_history WHERE user_id = ? ORDER BY scan_date DESC, scan_time DESC LIMIT 50");
        $stmt->execute([$userId]);
        $scans = $stmt->fetchAll();

        json_response(['status' => 'success', 'data' => $scans]);
    }

    json_response(['status' => 'error', 'message' => 'Method not allowed.'], 405);
} catch (Throwable $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
