<?php
/**
 * Administrator Sign Out Handler
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';

admin_logout();
header('Location: ' . base_url('login.php?loggedout=1'));
exit;
