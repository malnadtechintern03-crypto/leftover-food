<?php
/**
 * Helper Utilities & Security Functions
 */

declare(strict_types=1);

/**
 * Escapes HTML characters to prevent XSS attacks.
 */
function e(?string $value): string {
    return htmlspecialchars((string)($value ?? ''), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/**
 * Detects and returns the dynamic base URL of the admin panel.
 */
function base_url(string $path = ''): string {
    static $base = null;
    if ($base === null) {
        $scriptName = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '');
        
        // Check if hosted under /grocery_admin/ or /backend/
        if (str_contains($scriptName, '/grocery_admin/')) {
            $base = '/grocery_admin';
        } elseif (str_contains($scriptName, '/backend/')) {
            $base = '/backend';
        } else {
            // Direct root or port-based virtual host (e.g. php -S localhost:8000)
            $base = '';
        }
    }

    $cleanPath = ltrim($path, '/');
    return $base . ($cleanPath !== '' ? '/' . $cleanPath : '');
}

/**
 * Generates or retrieves a CSRF token for the current session.
 */
function csrf_token(): string {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/**
 * Generates an HTML hidden input containing the CSRF token.
 */
function csrf_field(): string {
    return '<input type="hidden" name="csrf_token" value="' . e(csrf_token()) . '">';
}

/**
 * Validates the submitted CSRF token.
 */
function verify_csrf(): bool {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        return true;
    }
    $submittedToken = $_POST['csrf_token'] ?? $_SERVER['HTTP_X_CSRF_TOKEN'] ?? '';
    if (empty($submittedToken) || empty($_SESSION['csrf_token'])) {
        return false;
    }
    return hash_equals($_SESSION['csrf_token'], $submittedToken);
}

/**
 * Sets a flash message to display on the next page load.
 */
function set_flash(string $type, string $message): void {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $_SESSION['flash'] = [
        'type' => $type, // success, error, warning, info
        'message' => $message,
    ];
}

/**
 * Retrieves and clears the current flash message if one exists.
 */
function get_flash(): ?array {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (isset($_SESSION['flash'])) {
        $flash = $_SESSION['flash'];
        unset($_SESSION['flash']);
        return $flash;
    }
    return null;
}

/**
 * Renders the flash message HTML alert if available.
 */
function render_flash(): string {
    $flash = get_flash();
    if (!$flash) {
        return '';
    }

    $type = $flash['type'] === 'error' ? 'danger' : $flash['type'];
    $icon = match ($type) {
        'success' => 'check_circle',
        'danger' => 'error',
        'warning' => 'warning',
        default => 'info',
    };

    return '<div class="alert alert-' . e($type) . ' d-flex align-items-center mb-4" role="alert">'
        . '<span class="material-symbols-rounded me-2 fs-5">' . $icon . '</span>'
        . '<div>' . e($flash['message']) . '</div>'
        . '<button type="button" class="btn-close ms-auto" data-bs-dismiss="alert" aria-label="Close"></button>'
        . '</div>';
}

/**
 * Formats a date string into readable format (e.g. 'Oct 14, 2026').
 */
function format_date(?string $dateStr, string $format = 'M d, Y'): string {
    if (!$dateStr) return '—';
    try {
        $dt = new DateTime($dateStr);
        return $dt->format($format);
    } catch (Exception) {
        return $dateStr;
    }
}

/**
 * Sends a clean JSON response with status code.
 */
function json_response(mixed $data, int $statusCode = 200): void {
    header('Content-Type: application/json; charset=utf-8', true, $statusCode);
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        exit(0);
    }

    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}
