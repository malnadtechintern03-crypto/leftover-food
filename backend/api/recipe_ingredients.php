<?php
/**
 * REST API - Recipe Ingredients Endpoint
 * GET /api/recipe_ingredients.php?recipe_id=1
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'GET') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only GET is supported.'], 405);
}

$recipeId = (int)($_GET['recipe_id'] ?? 0);
if ($recipeId <= 0) {
    json_response(['status' => 'error', 'message' => 'Missing or invalid recipe_id parameter.'], 400);
}

try {
    $db = Database::getConnection();

    $stmt = $db->prepare('
        SELECT id, recipe_id, ingredient_name, quantity, unit, is_required, created_at
        FROM recipe_ingredients
        WHERE recipe_id = ?
        ORDER BY is_required DESC, id ASC
    ');
    $stmt->execute([$recipeId]);
    $ingredients = $stmt->fetchAll();

    json_response([
        'status' => 'success',
        'recipe_id' => $recipeId,
        'count' => count($ingredients),
        'data' => $ingredients,
    ]);
} catch (Exception $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
