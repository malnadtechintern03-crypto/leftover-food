<?php
/**
 * ScanSmart Application Global Configuration
 */

declare(strict_types=1);

return [
    'app_name' => 'ScanSmart – Universal Product Scanner & Smart Inventory',
    'app_short_name' => 'ScanSmart',
    'tagline' => 'Scan Anything. Know Everything. Never Miss an Expiry.',
    'version' => '1.0.0',
    'default_currency' => '₹',
    'default_reminder_days' => 7,
    'pagination_limit' => 20,
    'server_ip' => '192.168.31.187',
    'api_url' => 'http://192.168.31.187/leftover/admin/api',
    'upload' => [
        'directory' => __DIR__ . '/../uploads/products/',
        'url' => 'uploads/products/',
        'max_size_bytes' => 5 * 1024 * 1024, // 5MB
        'allowed_types' => ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'],
        'allowed_extensions' => ['jpg', 'jpeg', 'png', 'webp'],
    ],
    'roles' => [
        'super_admin' => 'Super Admin',
        'admin' => 'Admin',
        'editor' => 'Editor',
        'viewer' => 'Viewer',
    ],
];
