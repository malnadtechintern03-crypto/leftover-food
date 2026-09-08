<?php
/**
 * REST API - Unknown Product Reporting Endpoint
 * POST /api/unknown-products.php (Report unrecognized barcode / OCR scan)
 * GET /api/unknown-products.php (Check triage status of a barcode)
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

        $barcode = trim((string)($input['barcode'] ?? ''));
        if ($barcode === '') {
            json_response(['status' => 'error', 'message' => 'Barcode is required.'], 400);
        }

        $productName = !empty($input['product_name']) ? trim((string)$input['product_name']) : null;
        $ocrText = !empty($input['ocr_text']) ? trim((string)$input['ocr_text']) : null;
        $userId = !empty($input['user_id']) ? trim((string)$input['user_id']) : 'default_user';
        $scanType = !empty($input['scan_type']) ? trim((string)$input['scan_type']) : 'Barcode';
        $suggestedCat = !empty($input['suggested_category']) ? trim((string)$input['suggested_category']) : null;

        // Prevent duplicate queue entries for same barcode
        $check = $db->prepare("SELECT id FROM unknown_products WHERE barcode = ? AND review_status = 'Pending Review' LIMIT 1");
        $check->execute([$barcode]);
        if (!$check->fetch()) {
            $stmt = $db->prepare("
                INSERT INTO unknown_products (barcode, product_name, ocr_text, user_id, scan_type, suggested_category, review_status)
                VALUES (?, ?, ?, ?, ?, ?, 'Pending Review')
            ");
            $stmt->execute([$barcode, $productName, $ocrText, $userId, $scanType, $suggestedCat]);
        }

        json_response(['status' => 'success', 'message' => 'Unrecognized product reported to admin triage queue.'], 201);
    }

    if ($method === 'GET') {
        $barcode = trim((string)($_GET['barcode'] ?? ''));
        if ($barcode === '') {
            json_response(['status' => 'error', 'message' => 'Barcode query parameter is required.'], 400);
        }

        $stmt = $db->prepare("SELECT * FROM unknown_products WHERE barcode = ? ORDER BY created_at DESC LIMIT 1");
        $stmt->execute([$barcode]);
        $res = $stmt->fetch();

        if ($res) {
            json_response(['status' => 'success', 'data' => $res]);
        } else {
            json_response(['status' => 'error', 'message' => 'No record found for this barcode.'], 404);
        }
    }

    json_response(['status' => 'error', 'message' => 'Method not allowed.'], 405);
} catch (Throwable $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
