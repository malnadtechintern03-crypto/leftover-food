<?php
/**
 * Admin Authentication & Session Security Layer
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/functions.php';

// Configure and start secure PHP session if not already active
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_httponly', '1');
    ini_set('session.use_only_cookies', '1');
    ini_set('session.cookie_samesite', 'Lax');
    session_start();
}

// 60 minutes inactivity timeout
const SESSION_TIMEOUT_SECONDS = 3600;

if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity'] > SESSION_TIMEOUT_SECONDS)) {
        // Session expired
        admin_logout();
        header('Location: ' . base_url('login.php?expired=1'));
        exit;
    }
    $_SESSION['last_activity'] = time();
}

/**
 * Checks if the current request has an authenticated admin session.
 */
function is_admin_logged_in(): bool {
    return isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
}

/**
 * Returns data of current logged in admin.
 */
function get_logged_in_admin(): ?array {
    if (!is_admin_logged_in()) {
        return null;
    }
    return [
        'id' => $_SESSION['admin_id'] ?? null,
        'name' => $_SESSION['admin_name'] ?? 'Administrator',
        'email' => $_SESSION['admin_email'] ?? '',
        'role' => $_SESSION['admin_role'] ?? 'admin',
    ];
}

/**
 * Route protection guard: Redirects to login page if unauthenticated.
 */
function require_admin(): void {
    if (!is_admin_logged_in()) {
        $returnUrl = urlencode($_SERVER['REQUEST_URI'] ?? '');
        header('Location: ' . base_url('login.php?return=' . $returnUrl));
        exit;
    }
}

/**
 * Authenticates admin against MySQL database using bcrypt password_verify().
 */
function admin_login(string $email, string $password): bool {
    $db = Database::getConnection();
    $stmt = $db->prepare('SELECT id, name, email, password, role, status FROM admins WHERE email = ? LIMIT 1');
    $stmt->execute([trim($email)]);
    $admin = $stmt->fetch();

    if (!$admin) {
        return false;
    }

    if ($admin['status'] !== 'active') {
        return false;
    }

    if (password_verify($password, $admin['password'])) {
        // Regenerate session ID to prevent session fixation
        session_regenerate_id(true);

        $_SESSION['admin_logged_in'] = true;
        $_SESSION['admin_id'] = (int)$admin['id'];
        $_SESSION['admin_name'] = $admin['name'];
        $_SESSION['admin_email'] = $admin['email'];
        $_SESSION['admin_role'] = $admin['role'];
        $_SESSION['last_activity'] = time();

        // Update last login timestamp
        $updateStmt = $db->prepare('UPDATE admins SET last_login = NOW() WHERE id = ?');
        $updateStmt->execute([$admin['id']]);

        return true;
    }

    return false;
}

/**
 * Logs out the administrator and completely destroys session.
 */
function admin_logout(): void {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();
        setcookie(
            session_name(),
            '',
            time() - 42000,
            $params['path'],
            $params['domain'],
            $params['secure'],
            $params['httponly']
        );
    }
    session_destroy();
}
