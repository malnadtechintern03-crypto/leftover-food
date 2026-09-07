<?php
/**
 * Recipe Management - Delete Recipe Handler
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . base_url('recipes/index.php'));
    exit;
}

if (!verify_csrf()) {
    set_flash('danger', 'Security validation failed.');
    header('Location: ' . base_url('recipes/index.php'));
    exit;
}

$id = (int)($_POST['id'] ?? 0);
if ($id <= 0) {
    set_flash('danger', 'Invalid recipe ID.');
    header('Location: ' . base_url('recipes/index.php'));
    exit;
}

$db = Database::getConnection();

$stmt = $db->prepare('SELECT title FROM recipes WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$recipe = $stmt->fetch();

if (!$recipe) {
    set_flash('danger', 'Recipe not found.');
    header('Location: ' . base_url('recipes/index.php'));
    exit;
}

// Delete recipe (foreign key ON DELETE CASCADE automatically removes recipe_ingredients)
$deleteStmt = $db->prepare('DELETE FROM recipes WHERE id = ?');
$deleteStmt->execute([$id]);

set_flash('success', "Recipe '{$recipe['title']}' deleted successfully.");
header('Location: ' . base_url('recipes/index.php'));
exit;
