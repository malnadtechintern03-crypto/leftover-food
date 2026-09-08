<?php
/**
 * ScanSmart Helper Utilities & Security Functions
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

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
        
        if (preg_match('#^(.*?/admin)(?:/|$)#i', $scriptName, $matches)) {
            $base = $matches[1];
        } elseif (str_contains($scriptName, '/leftover-food/')) {
            $base = '/leftover-food/admin';
        } elseif (str_contains($scriptName, '/leftover/')) {
            $base = '/leftover/admin';
        } elseif (str_contains($scriptName, '/scansmart/')) {
            $base = '/scansmart/admin';
        } elseif (str_contains($scriptName, '/grocery_admin/')) {
            $base = '/grocery_admin';
        } elseif (str_contains($scriptName, '/backend/')) {
            $base = '/backend';
        } else {
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

/**
 * Logs administrative action into the audit trail table.
 */
function log_admin_activity(string $action, string $description, ?int $adminId = null): void {
    try {
        $db = Database::getConnection();
        $adminName = 'System';
        if ($adminId === null && isset($_SESSION['admin_id'])) {
            $adminId = (int)$_SESSION['admin_id'];
            $adminName = $_SESSION['admin_name'] ?? 'Admin';
        } elseif ($adminId !== null) {
            $stmt = $db->prepare('SELECT name FROM admins WHERE id = ? LIMIT 1');
            $stmt->execute([$adminId]);
            $adminName = $stmt->fetchColumn() ?: 'Admin #' . $adminId;
        }

        $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        $insert = $db->prepare('INSERT INTO admin_activity_logs (admin_id, admin_name, action, description, ip_address) VALUES (?, ?, ?, ?, ?)');
        $insert->execute([$adminId, $adminName, $action, $description, $ip]);
    } catch (Throwable) {
        // Fail silently so activity logging never crashes caller flow
    }
}

/**
 * Securely uploads a product image and returns the relative path or error.
 */
function upload_product_image(array $file): array {
    if (!isset($file['error']) || is_array($file['error'])) {
        return ['success' => false, 'error' => 'Invalid file upload parameters.'];
    }

    if ($file['error'] === UPLOAD_ERR_NO_FILE) {
        return ['success' => false, 'error' => 'No file uploaded.'];
    }

    if ($file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'error' => 'File upload failed with error code: ' . $file['error']];
    }

    // Limit to 5MB
    if ($file['size'] > 5 * 1024 * 1024) {
        return ['success' => false, 'error' => 'File size exceeds the 5MB maximum limit.'];
    }

    // Validate MIME type
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file($file['tmp_name']);
    $allowedMimes = [
        'image/jpeg' => 'jpg',
        'image/pjpeg' => 'jpg',
        'image/png'  => 'png',
        'image/webp' => 'webp',
    ];

    if (!array_key_exists($mime, $allowedMimes)) {
        return ['success' => false, 'error' => 'Invalid image format. Only JPG, PNG, and WEBP are allowed.'];
    }

    $ext = $allowedMimes[$mime];
    $uploadDir = __DIR__ . '/../uploads/products/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    // Generate random safe filename
    $safeName = 'prod_' . bin2hex(random_bytes(10)) . '_' . time() . '.' . $ext;
    $targetPath = $uploadDir . $safeName;

    if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
        return ['success' => false, 'error' => 'Failed to save uploaded file to destination directory.'];
    }

    return [
        'success' => true,
        'filename' => $safeName,
        'relative_path' => 'uploads/products/' . $safeName,
        'url' => base_url('uploads/products/' . $safeName),
    ];
}

/**
 * Exports data rows to CSV download with UTF-8 BOM for Excel compatibility.
 */
function export_to_csv(string $filename, array $headers, array $rows): void {
    if (ob_get_level()) {
        ob_end_clean();
    }

    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Pragma: no-cache');
    header('Expires: 0');

    $output = fopen('php://output', 'w');
    // Write UTF-8 BOM
    fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF));

    // Write header
    fputcsv($output, $headers);

    // Write data rows
    foreach ($rows as $row) {
        fputcsv($output, $row);
    }

    fclose($output);
    exit;
}

/**
 * Gets application setting from database.
 */
function get_app_setting(string $key, ?string $default = null): string {
    try {
        $db = Database::getConnection();
        $stmt = $db->prepare('SELECT setting_value FROM app_settings WHERE setting_key = ? LIMIT 1');
        $stmt->execute([$key]);
        $val = $stmt->fetchColumn();
        return $val !== false && $val !== null ? (string)$val : ($default ?? '');
    } catch (Throwable) {
        return $default ?? '';
    }
}

/**
 * Sets application setting in database.
 */
function set_app_setting(string $key, string $value, ?string $description = null): void {
    try {
        $db = Database::getConnection();
        $stmt = $db->prepare('INSERT INTO app_settings (setting_key, setting_value, description) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), description = COALESCE(VALUES(description), description)');
        $stmt->execute([$key, $value, $description]);
    } catch (Throwable) {
        // Fail silently
    }
}
