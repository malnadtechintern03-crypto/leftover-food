<?php
/**
 * Root Index - Routes to Dashboard or Login
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

if (is_admin_logged_in()) {
    header('Location: ' . base_url('dashboard.php'));
} else {
    header('Location: ' . base_url('login.php'));
}
exit;
