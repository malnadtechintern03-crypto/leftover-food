<?php
/**
 * REST API - Mobile User Authentication Endpoint
 * POST /api/user-auth.php
 * Handles Login, Register, Logout, and Profile queries for mobile app users.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    json_response(['status' => 'ok'], 200);
}

// Read JSON input or fallback to $_POST / $_GET
$raw = file_get_contents('php://input');
$input = !empty($raw) ? json_decode($raw, true) : $_POST;
if (!is_array($input)) {
    $input = [];
}

$action = trim((string)($input['action'] ?? $_GET['action'] ?? 'login'));

try {
    $db = Database::getConnection();

    // -------------------------------------------------------------
    // 1. ACTION: LOGIN
    // -------------------------------------------------------------
    if ($action === 'login') {
        if ($method !== 'POST') {
            json_response(['status' => 'error', 'message' => 'Only POST method is allowed for login.'], 405);
        }

        $email = strtolower(trim((string)($input['email'] ?? '')));
        $password = (string)($input['password'] ?? '');

        if ($email === '' || $password === '') {
            json_response(['status' => 'error', 'message' => 'Email address and password are required.'], 400);
        }

        $stmt = $db->prepare('SELECT id, name, email, password, role, status, products_count, scans_count, created_at FROM users WHERE LOWER(email) = ? LIMIT 1');
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if (!$user) {
            json_response(['status' => 'error', 'message' => 'Invalid email address or password.'], 401);
        }

        // Verify password
        $hashed = $user['password'] ?? '';
        $isValid = false;
        if (!empty($hashed)) {
            $isValid = password_verify($password, $hashed);
        } else {
            // For legacy/synced users without a hashed password, check default credentials
            $isValid = ($password === 'user123' || $password === 'password');
        }

        if (!$isValid) {
            json_response(['status' => 'error', 'message' => 'Invalid email address or password.'], 401);
        }

        if ($user['status'] !== 'active') {
            json_response([
                'status' => 'error',
                'message' => 'This account is currently inactive or suspended. Please contact support.'
            ], 403);
        }

        // Update last login timestamp
        $updateStmt = $db->prepare('UPDATE users SET last_login = NOW() WHERE id = ?');
        $updateStmt->execute([$user['id']]);

        // Generate session token
        $token = 'tok_' . bin2hex(random_bytes(24));

        json_response([
            'status' => 'success',
            'message' => 'Authentication successful.',
            'token' => $token,
            'user' => [
                'id' => (string)$user['id'],
                'name' => (string)$user['name'],
                'email' => (string)$user['email'],
                'role' => (string)($user['role'] ?? 'user'),
                'status' => (string)$user['status'],
                'created_at' => (string)($user['created_at'] ?? ''),
            ],
        ], 200);
    }

    // -------------------------------------------------------------
    // 2. ACTION: REGISTER
    // -------------------------------------------------------------
    if ($action === 'register') {
        if ($method !== 'POST') {
            json_response(['status' => 'error', 'message' => 'Only POST method is allowed for registration.'], 405);
        }

        $name = trim((string)($input['name'] ?? ''));
        $email = strtolower(trim((string)($input['email'] ?? '')));
        $password = (string)($input['password'] ?? '');

        if ($name === '') {
            json_response(['status' => 'error', 'message' => 'Full name is required.'], 400);
        }

        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            json_response(['status' => 'error', 'message' => 'A valid email address is required.'], 400);
        }

        if (strlen($password) < 6) {
            json_response(['status' => 'error', 'message' => 'Password must be at least 6 characters in length.'], 400);
        }

        // Check for duplicate email
        $checkStmt = $db->prepare('SELECT id FROM users WHERE LOWER(email) = ? LIMIT 1');
        $checkStmt->execute([$email]);
        if ($checkStmt->fetch()) {
            json_response([
                'status' => 'error',
                'message' => 'An account with this email address already exists. Please sign in instead.'
            ], 409);
        }

        $userId = 'user_' . bin2hex(random_bytes(8));
        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

        $insertStmt = $db->prepare("
            INSERT INTO users (id, name, email, password, role, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, 'user', 'active', NOW(), NOW())
        ");
        $insertStmt->execute([$userId, $name, $email, $hashedPassword]);

        $token = 'tok_' . bin2hex(random_bytes(24));

        json_response([
            'status' => 'success',
            'message' => 'Account created successfully.',
            'token' => $token,
            'user' => [
                'id' => $userId,
                'name' => $name,
                'email' => $email,
                'role' => 'user',
                'status' => 'active',
                'created_at' => date('Y-m-d H:i:s'),
            ],
        ], 201);
    }

    // -------------------------------------------------------------
    // 3. ACTION: LOGOUT
    // -------------------------------------------------------------
    if ($action === 'logout') {
        $userId = trim((string)($input['user_id'] ?? $_GET['user_id'] ?? ''));
        json_response([
            'status' => 'success',
            'message' => 'User logged out successfully.',
            'user_id' => $userId,
        ], 200);
    }

    // -------------------------------------------------------------
    // 4. ACTION: PROFILE / ME
    // -------------------------------------------------------------
    if ($action === 'me' || $action === 'profile') {
        $userId = trim((string)($input['user_id'] ?? $_GET['user_id'] ?? ''));
        if ($userId === '') {
            json_response(['status' => 'error', 'message' => 'User ID is required.'], 400);
        }

        $stmt = $db->prepare('SELECT id, name, email, role, status, products_count, scans_count, created_at FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if (!$user) {
            json_response(['status' => 'error', 'message' => 'User not found.'], 404);
        }

        json_response([
            'status' => 'success',
            'user' => [
                'id' => (string)$user['id'],
                'name' => (string)$user['name'],
                'email' => (string)$user['email'],
                'role' => (string)($user['role'] ?? 'user'),
                'status' => (string)$user['status'],
                'products_count' => (int)($user['products_count'] ?? 0),
                'scans_count' => (int)($user['scans_count'] ?? 0),
                'created_at' => (string)($user['created_at'] ?? ''),
            ],
        ], 200);
    }

    json_response(['status' => 'error', 'message' => "Unsupported action '{$action}'."], 400);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Internal server error: ' . $e->getMessage()
    ], 500);
}
