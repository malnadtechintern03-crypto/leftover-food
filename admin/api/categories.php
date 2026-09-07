<?php
/**
 * REST API - Categories Endpoint
 * GET /api/categories.php
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
        SELECT id, name, description, icon, color, status, created_at, updated_at
        FROM categories
        WHERE status = 'active'
        ORDER BY name ASC
    ");
    $categories = $stmt->fetchAll();

    json_response([
        'status' => 'success',
        'count' => count($categories),
        'data' => $categories,
    ]);
} catch (Exception $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
