<?php
/**
 * Admin Panel - Delete Product Action
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . base_url('products/index.php'));
    exit;
}

if (!verify_csrf()) {
    set_flash('error', 'Security token invalid or expired. Please try again.');
    header('Location: ' . base_url('products/index.php'));
    exit;
}

$id = trim($_POST['id'] ?? '');

if ($id === '') {
    set_flash('error', 'Invalid product identifier.');
    header('Location: ' . base_url('products/index.php'));
    exit;
}

$db = Database::getConnection();

try {
    // Delete product (cascades to product_reminders via foreign key)
    $stmt = $db->prepare('DELETE FROM products WHERE id = ?');
    $stmt->execute([$id]);

    set_flash('success', 'Product deleted successfully.');
} catch (Throwable $e) {
    set_flash('error', 'Failed to delete product: ' . $e->getMessage());
}

header('Location: ' . base_url('products/index.php'));
exit;
