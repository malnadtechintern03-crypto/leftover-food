<?php
/**
 * REST API - Admin Authentication Endpoint
 * POST /api/auth.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only POST is supported.'], 405);
}

// Read JSON body or POST form data
$input = json_decode(file_get_contents('php://input'), true);
$email = trim($input['email'] ?? $_POST['email'] ?? '');
$password = (string)($input['password'] ?? $_POST['password'] ?? '');

if ($email === '' || $password === '') {
    json_response(['status' => 'error', 'message' => 'Email and password are required.'], 400);
}

try {
    $db = Database::getConnection();
    $stmt = $db->prepare('SELECT id, name, email, password, role, status FROM admins WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $admin = $stmt->fetch();

    if (!$admin || !password_verify($password, $admin['password'])) {
        json_response(['status' => 'error', 'message' => 'Invalid credentials.'], 401);
    }

    if ($admin['status'] !== 'active') {
        json_response(['status' => 'error', 'message' => 'Account is inactive. Contact system administrator.'], 403);
    }

    // Update last login
    $updateStmt = $db->prepare('UPDATE admins SET last_login = NOW() WHERE id = ?');
    $updateStmt->execute([$admin['id']]);

    json_response([
        'status' => 'success',
        'message' => 'Authentication successful.',
        'admin' => [
            'id' => (int)$admin['id'],
            'name' => $admin['name'],
            'email' => $admin['email'],
            'role' => $admin['role'],
        ],
    ]);
} catch (Exception $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
