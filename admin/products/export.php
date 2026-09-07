<?php
/**
 * Admin Panel - Products CSV Export
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

$search = trim($_GET['q'] ?? '');
$category = trim($_GET['category'] ?? '');
$status = trim($_GET['status'] ?? '');

$where = ['p.is_consumed = 0'];
$params = [];

if ($search !== '') {
    $where[] = '(p.name LIKE ? OR p.brand LIKE ? OR p.barcode LIKE ? OR p.subcategory LIKE ?)';
    $like = "%{$search}%";
    $params = array_merge($params, [$like, $like, $like, $like]);
}

if ($category !== '') {
    $where[] = 'p.category = ?';
    $params[] = $category;
}

if ($status !== '') {
    $today = date('Y-m-d');
    switch (strtolower($status)) {
        case 'expired':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date < ?';
            $params[] = $today;
            break;
        case 'expiring_today':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date = ?';
            $params[] = $today;
            break;
        case 'expiring_soon':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date >= ? AND p.expiry_date <= DATE_ADD(?, INTERVAL 7 DAY)';
            $params[] = $today;
            $params[] = $today;
            break;
        case 'within_30_days':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date > DATE_ADD(?, INTERVAL 7 DAY) AND p.expiry_date <= DATE_ADD(?, INTERVAL 30 DAY)';
            $params[] = $today;
            $params[] = $today;
            break;
        case 'safe':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date > DATE_ADD(?, INTERVAL 7 DAY)';
            $params[] = $today;
            break;
        case 'no_expiry':
            $where[] = 'p.expiry_date IS NULL';
            break;
    }
}

$whereClause = 'WHERE ' . implode(' AND ', $where);

$sql = "SELECT p.*,
        CASE 
            WHEN p.expiry_date IS NULL THEN NULL 
            ELSE DATEDIFF(p.expiry_date, CURDATE()) 
        END AS days_remaining
        FROM products p
        {$whereClause}
        ORDER BY p.expiry_date IS NULL ASC, p.expiry_date ASC, p.name ASC";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$products = $stmt->fetchAll();

$filename = 'products_inventory_' . date('Y-m-d_His') . '.csv';

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="' . $filename . '"');
header('Pragma: no-cache');
header('Expires: 0');

$output = fopen('php://output', 'w');

// UTF-8 BOM for Excel compatibility
fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF));

// CSV Header
fputcsv($output, [
    'Product ID',
    'Product Name',
    'Brand',
    'Barcode',
    'Category',
    'Subcategory',
    'Quantity',
    'Unit',
    'Purchase Price',
    'Purchase Date',
    'Manufacturing Date',
    'Expiration Date',
    'Days Remaining',
    'Expiration Status',
    'Reminder Enabled',
    'Reminder Schedule',
    'Storage Location',
    'Notes',
    'Created At',
]);

foreach ($products as $p) {
    $daysRemaining = $p['days_remaining'] !== null ? (int)$p['days_remaining'] : 'N/A';
    $statusText = $p['expiry_date'] === null ? 'No Expiry Date' : ($p['days_remaining'] < 0 ? 'Expired' : ($p['days_remaining'] <= 2 ? 'Expiring Soon' : 'Safe'));

    fputcsv($output, [
        $p['id'],
        $p['name'],
        $p['brand'] ?? '',
        $p['barcode'] ?? '',
        $p['category'],
        $p['subcategory'] ?? '',
        $p['quantity'],
        $p['unit'],
        $p['purchase_price'] !== null ? number_format((float)$p['purchase_price'], 2) : '0.00',
        $p['purchase_date'] ?? '',
        $p['manufacturing_date'] ?? '',
        $p['expiry_date'] ?? 'No Expiry Date',
        $daysRemaining,
        $statusText,
        $p['reminder_enabled'] ? 'Yes' : 'No',
        $p['reminder_days_before'] ?? '',
        $p['storage_location'] ?? 'pantry',
        $p['notes'] ?? '',
        $p['created_at'] ?? '',
    ]);
}

fclose($output);
exit;
