<?php
/**
 * REST API - Recipes Endpoint
 * GET /api/recipes.php
 * GET /api/recipes.php?id=1
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'GET') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only GET is supported.'], 405);
}

$id = isset($_GET['id']) ? (int)$_GET['id'] : null;

try {
    $db = Database::getConnection();

    if ($id !== null && $id > 0) {
        // Single recipe details
        $stmt = $db->prepare('
            SELECT r.*, c.name AS category_name, c.color AS category_color
            FROM recipes r
            LEFT JOIN categories c ON r.category_id = c.id
            WHERE r.id = ? AND r.status = "published"
            LIMIT 1
        ');
        $stmt->execute([$id]);
        $recipe = $stmt->fetch();

        if (!$recipe) {
            json_response(['status' => 'error', 'message' => 'Recipe not found'], 404);
        }

        // Fetch ingredients
        $ingStmt = $db->prepare('
            SELECT id, ingredient_name, quantity, unit, is_required
            FROM recipe_ingredients
            WHERE recipe_id = ?
            ORDER BY is_required DESC, id ASC
        ');
        $ingStmt->execute([$id]);
        $recipe['ingredients'] = $ingStmt->fetchAll();

        // Convert instructions to list
        $instructions = $recipe['instructions'] ?? '';
        $recipe['instruction_steps'] = array_values(array_filter(
            array_map('trim', explode("\n", $instructions)),
            fn($line) => $line !== ''
        ));

        json_response([
            'status' => 'success',
            'data' => $recipe,
        ]);
    } else {
        // List all published recipes
        $stmt = $db->query('
            SELECT r.*, c.name AS category_name, c.color AS category_color
            FROM recipes r
            LEFT JOIN categories c ON r.category_id = c.id
            WHERE r.status = "published"
            ORDER BY r.id DESC
        ');
        $recipes = $stmt->fetchAll();

        // Batch fetch ingredients for all published recipes
        if (!empty($recipes)) {
            $recipeIds = array_column($recipes, 'id');
            $placeholders = implode(',', array_fill(0, count($recipeIds), '?'));
            
            $ingStmt = $db->prepare("
                SELECT id, recipe_id, ingredient_name, quantity, unit, is_required
                FROM recipe_ingredients
                WHERE recipe_id IN ($placeholders)
                ORDER BY is_required DESC, id ASC
            ");
            $ingStmt->execute($recipeIds);
            $allIngredients = $ingStmt->fetchAll();

            // Group by recipe_id
            $groupedIngredients = [];
            foreach ($allIngredients as $ing) {
                $groupedIngredients[$ing['recipe_id']][] = $ing;
            }

            foreach ($recipes as &$r) {
                $r['ingredients'] = $groupedIngredients[$r['id']] ?? [];
                
                // Also provide a flat array of ingredient names for easy client matching
                $r['ingredient_names'] = array_column($r['ingredients'], 'ingredient_name');

                $instructions = $r['instructions'] ?? '';
                $r['instruction_steps'] = array_values(array_filter(
                    array_map('trim', explode("\n", $instructions)),
                    fn($line) => $line !== ''
                ));
            }
            unset($r);
        }

        json_response([
            'status' => 'success',
            'count' => count($recipes),
            'data' => $recipes,
        ]);
    }
} catch (Exception $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
