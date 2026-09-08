<?php
/**
 * REST API - Mobile Users Endpoint
 * GET /api/users.php (List users or query user profile)
 * POST /api/users.php (Sync or register mobile user)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    json_response(['status' => 'ok'], 200);
}

try {
    $db = Database::getConnection();

    if ($method === 'GET') {
        $userId = trim((string)($_GET['id'] ?? ''));
        if ($userId !== '') {
            $stmt = $db->prepare('SELECT id, name, email, role, status, products_count, scans_count, created_at FROM users WHERE id = ? LIMIT 1');
            $stmt->execute([$userId]);
            $user = $stmt->fetch();
            if ($user) {
                json_response(['status' => 'success', 'data' => $user]);
            } else {
                json_response(['status' => 'error', 'message' => 'User not found.'], 404);
            }
        }

        $users = $db->query('SELECT id, name, email, role, status, products_count, scans_count, created_at FROM users ORDER BY created_at DESC')->fetchAll();
        json_response(['status' => 'success', 'data' => $users]);
    }

    if ($method === 'POST') {
        $raw = file_get_contents('php://input');
        $input = !empty($raw) ? json_decode($raw, true) : $_POST;

        $id = !empty($input['id']) ? trim((string)$input['id']) : 'user_' . bin2hex(random_bytes(8));
        $name = !empty($input['name']) ? trim((string)$input['name']) : 'Mobile User';
        $email = !empty($input['email']) ? trim((string)$input['email']) : $id . '@scansmart.local';

        $stmt = $db->prepare("
            INSERT INTO users (id, name, email, status)
            VALUES (?, ?, ?, 'active')
            ON DUPLICATE KEY UPDATE name = VALUES(name), last_login = NOW()
        ");
        $stmt->execute([$id, $name, $email]);

        json_response(['status' => 'success', 'message' => 'User registered/synced successfully.', 'user_id' => $id]);
    }

    json_response(['status' => 'error', 'message' => 'Method not allowed.'], 405);
} catch (Throwable $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
