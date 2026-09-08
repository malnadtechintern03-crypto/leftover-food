<?php
/**
 * REST API - Health & Status Check Endpoint
 * GET /api/status.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache, no-store, must-revalidate');

$startTime = microtime(true);

try {
    $db = Database::getConnection();
    $productCount = (int)$db->query('SELECT COUNT(*) FROM products')->fetchColumn();
    $recipeCount = (int)$db->query('SELECT COUNT(*) FROM recipes')->fetchColumn();
    $categoryCount = (int)$db->query('SELECT COUNT(*) FROM categories')->fetchColumn();
    
    $elapsedMs = round((microtime(true) - $startTime) * 1000, 2);

    echo json_encode([
        'status' => 'success',
        'app_name' => 'Home Pantry',
        'api_version' => '1.0.0',
        'db_connected' => true,
        'server_time' => date('c'),
        'latency_ms' => $elapsedMs,
        'stats' => [
            'products' => $productCount,
            'recipes' => $recipeCount,
            'categories' => $categoryCount,
        ],
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'app_name' => 'Home Pantry',
        'api_version' => '1.0.0',
        'db_connected' => false,
        'message' => 'Database connectivity error: ' . $e->getMessage(),
        'server_time' => date('c'),
    ], JSON_PRETTY_PRINT);
}
