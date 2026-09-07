<?php
/**
 * Announcement Management - Delete Announcement Handler
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . base_url('announcements/index.php'));
    exit;
}

if (!verify_csrf()) {
    set_flash('danger', 'Security validation failed.');
    header('Location: ' . base_url('announcements/index.php'));
    exit;
}

$id = (int)($_POST['id'] ?? 0);
if ($id <= 0) {
    set_flash('danger', 'Invalid announcement ID.');
    header('Location: ' . base_url('announcements/index.php'));
    exit;
}

$db = Database::getConnection();
$stmt = $db->prepare('DELETE FROM announcements WHERE id = ?');
$stmt->execute([$id]);

set_flash('success', 'Announcement deleted successfully.');
header('Location: ' . base_url('announcements/index.php'));
exit;
