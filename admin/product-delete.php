<?php
/**
 * ScanSmart Product Management - Delete Product Handler
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin', 'admin');

if (!verify_csrf()) {
    set_flash('error', 'Security token expired. Please try again.');
    header('Location: ' . base_url('products.php'));
    exit;
}

$id = trim((string)($_GET['id'] ?? ''));
if ($id === '') {
    set_flash('error', 'Product ID is missing.');
    header('Location: ' . base_url('products.php'));
    exit;
}

$db = Database::getConnection();

// Fetch product name for logging
$stmt = $db->prepare('SELECT name, barcode FROM products WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$prod = $stmt->fetch();

if (!$prod) {
    set_flash('error', 'Product not found.');
    header('Location: ' . base_url('products.php'));
    exit;
}

try {
    // Delete reminders
    $db->prepare('DELETE FROM product_reminders WHERE product_id = ?')->execute([$id]);

    // Delete product
    $delStmt = $db->prepare('DELETE FROM products WHERE id = ? LIMIT 1');
    $delStmt->execute([$id]);

    log_admin_activity('Delete Product', "Deleted product '{$prod['name']}' (Barcode: " . ($prod['barcode'] ?: 'None') . ")");
    set_flash('success', "Product '{$prod['name']}' was successfully deleted.");
} catch (Throwable $e) {
    set_flash('error', 'Failed to delete product: ' . $e->getMessage());
}

header('Location: ' . base_url('products.php'));
exit;
