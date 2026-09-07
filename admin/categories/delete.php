<?php
/**
 * Category Management - Delete Category Handler
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . base_url('categories/index.php'));
    exit;
}

if (!verify_csrf()) {
    set_flash('danger', 'Security validation failed. Please try again.');
    header('Location: ' . base_url('categories/index.php'));
    exit;
}

$id = (int)($_POST['id'] ?? 0);
if ($id <= 0) {
    set_flash('danger', 'Invalid category ID.');
    header('Location: ' . base_url('categories/index.php'));
    exit;
}

$db = Database::getConnection();

// Check if category exists
$stmt = $db->prepare('SELECT name FROM categories WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$category = $stmt->fetch();

if (!$category) {
    set_flash('danger', 'Category not found.');
    header('Location: ' . base_url('categories/index.php'));
    exit;
}

// Safety check: Prevent deletion if active recipes are mapped to this category
$recipeCheckStmt = $db->prepare('SELECT COUNT(*) FROM recipes WHERE category_id = ?');
$recipeCheckStmt->execute([$id]);
$recipesCount = (int)$recipeCheckStmt->fetchColumn();

if ($recipesCount > 0) {
    set_flash('warning', "Cannot delete category '{$category['name']}' because it is linked to {$recipesCount} recipe(s). Please reassign those recipes or set this category to Inactive.");
    header('Location: ' . base_url('categories/index.php'));
    exit;
}

// Safe to delete
$deleteStmt = $db->prepare('DELETE FROM categories WHERE id = ?');
$deleteStmt->execute([$id]);

set_flash('success', "Category '{$category['name']}' deleted successfully.");
header('Location: ' . base_url('categories/index.php'));
exit;
