<?php
/**
 * ScanSmart Category Management - Delete Category Handler
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin', 'admin');

if (!verify_csrf()) {
    set_flash('error', 'Security token expired. Please try again.');
    header('Location: ' . base_url('categories.php'));
    exit;
}

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    set_flash('error', 'Invalid category ID.');
    header('Location: ' . base_url('categories.php'));
    exit;
}

$db = Database::getConnection();

// Fetch category details
$stmt = $db->prepare('SELECT name FROM categories WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$cat = $stmt->fetch();

if (!$cat) {
    set_flash('error', 'Category not found.');
    header('Location: ' . base_url('categories.php'));
    exit;
}

// Safety check: Count active products in this category
$checkStmt = $db->prepare('SELECT COUNT(*) FROM products WHERE (category_id = ? OR category = ?) AND status != "Archived"');
$checkStmt->execute([$id, $cat['name']]);
$productCount = (int)$checkStmt->fetchColumn();

if ($productCount > 0) {
    set_flash('error', "Cannot delete category '{$cat['name']}': {$productCount} products are currently assigned to it. Please reassign the products to another category first.");
    header('Location: ' . base_url('categories.php'));
    exit;
}

try {
    // Delete subcategories and keyword rules
    $db->prepare('DELETE FROM subcategories WHERE category_id = ?')->execute([$id]);
    $db->prepare('DELETE FROM category_keywords WHERE category_id = ?')->execute([$id]);

    // Delete category
    $del = $db->prepare('DELETE FROM categories WHERE id = ? LIMIT 1');
    $del->execute([$id]);

    log_admin_activity('Delete Category', "Deleted category '{$cat['name']}' (ID: {$id})");
    set_flash('success', "Category '{$cat['name']}' was successfully deleted.");
} catch (Throwable $e) {
    set_flash('error', 'Failed to delete category: ' . $e->getMessage());
}

header('Location: ' . base_url('categories.php'));
exit;
