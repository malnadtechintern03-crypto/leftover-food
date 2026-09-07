<?php
/**
 * REST API - Announcements Endpoint
 * GET /api/announcements.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'GET') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only GET is supported.'], 405);
}

try {
    $db = Database::getConnection();

    $stmt = $db->query("
        SELECT id, title, message, image_url, start_date, end_date, created_at
        FROM announcements
        WHERE status = 'published'
          AND CURRENT_DATE() BETWEEN start_date AND end_date
        ORDER BY id DESC
    ");
    $announcements = $stmt->fetchAll();

    json_response([
        'status' => 'success',
        'count' => count($announcements),
        'data' => $announcements,
    ]);
} catch (Exception $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
