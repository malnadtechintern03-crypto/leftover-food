<?php
/**
 * Admin Panel - Delete Administrator Account
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();
$currentAdmin = get_logged_in_admin();

$userId = (int)($_GET['id'] ?? $_POST['id'] ?? 0);
$token = (string)($_GET['csrf_token'] ?? $_POST['csrf_token'] ?? '');

if ($token === '' || empty($_SESSION['csrf_token']) || !hash_equals($_SESSION['csrf_token'], $token)) {
    set_flash('danger', 'Security validation failed (invalid CSRF token).');
    header('Location: ' . base_url('users/index.php'));
    exit;
}

if ($userId <= 0) {
    set_flash('danger', 'Invalid user ID specified.');
    header('Location: ' . base_url('users/index.php'));
    exit;
}

// Cannot delete own account
if ($userId === (int)($currentAdmin['id'] ?? 0)) {
    set_flash('danger', 'You cannot delete your own active administrator account.');
    header('Location: ' . base_url('users/index.php'));
    exit;
}

$userStmt = $db->prepare('SELECT id, name, role FROM admins WHERE id = ? LIMIT 1');
$userStmt->execute([$userId]);
$targetUser = $userStmt->fetch();

if (!$targetUser) {
    set_flash('danger', 'Administrator account not found.');
    header('Location: ' . base_url('users/index.php'));
    exit;
}

// Check if last super_admin
if ($targetUser['role'] === 'super_admin') {
    $superCount = (int)$db->query("SELECT COUNT(*) FROM admins WHERE role = 'super_admin'")->fetchColumn();
    if ($superCount <= 1) {
        set_flash('danger', 'Cannot delete the only remaining Super Administrator account.');
        header('Location: ' . base_url('users/index.php'));
        exit;
    }
}

// Perform deletion
$deleteStmt = $db->prepare('DELETE FROM admins WHERE id = ?');
$deleteStmt->execute([$userId]);

set_flash('success', "Administrator '{$targetUser['name']}' was permanently removed.");
header('Location: ' . base_url('users/index.php'));
exit;
