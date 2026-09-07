<?php
/**
 * REST API - Universal Inventory Products Endpoint
 * GET /api/inventory.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Only GET is supported.'], 405);
}

try {
    $db = Database::getConnection();

    $search = isset($_GET['search']) ? trim((string)$_GET['search']) : '';
    $category = isset($_GET['category']) ? trim((string)$_GET['category']) : '';
    $status = isset($_GET['status']) ? trim((string)$_GET['status']) : '';
    $location = isset($_GET['location']) ? trim((string)$_GET['location']) : '';
    $sort = isset($_GET['sort']) ? trim((string)$_GET['sort']) : 'expiryAsc';
    $includeConsumed = isset($_GET['include_consumed']) && $_GET['include_consumed'] === '1';

    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = max(1, min(100, (int)($_GET['limit'] ?? 50)));
    $offset = ($page - 1) * $limit;

    $where = [];
    $params = [];

    if (!$includeConsumed) {
        $where[] = 'p.is_consumed = 0';
    }

    if ($search !== '') {
        $where[] = '(p.name LIKE ? OR p.brand LIKE ? OR p.barcode LIKE ? OR p.subcategory LIKE ? OR p.notes LIKE ?)';
        $searchPattern = "%{$search}%";
        $params = array_merge($params, [$searchPattern, $searchPattern, $searchPattern, $searchPattern, $searchPattern]);
    }

    if ($category !== '') {
        $where[] = 'p.category = ?';
        $params[] = $category;
    }

    if ($location !== '') {
        $where[] = 'p.storage_location = ?';
        $params[] = $location;
    }

    if ($status !== '') {
        $today = date('Y-m-d');
        switch (strtolower($status)) {
            case 'expired':
                $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date < ?';
                $params[] = $today;
                break;
            case 'expiring_today':
            case 'expiringtoday':
                $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date = ?';
                $params[] = $today;
                break;
            case 'expiring_soon':
            case 'expiringsoon':
                $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date >= ? AND p.expiry_date <= DATE_ADD(?, INTERVAL 7 DAY)';
                $params[] = $today;
                $params[] = $today;
                break;
            case 'safe':
                $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date > DATE_ADD(?, INTERVAL 7 DAY)';
                $params[] = $today;
                break;
            case 'no_expiry':
            case 'noexpiry':
                $where[] = 'p.expiry_date IS NULL';
                break;
        }
    }

    $whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

    // Sort order mapping
    $orderBy = match ($sort) {
        'dateAddedAsc' => 'p.created_at ASC',
        'dateAddedDesc' => 'p.created_at DESC',
        'nameAsc' => 'p.name ASC',
        'nameDesc' => 'p.name DESC',
        'quantityAsc' => 'p.quantity ASC',
        'quantityDesc' => 'p.quantity DESC',
        'categoryAsc' => 'p.category ASC, p.name ASC',
        'expiryDesc' => 'p.expiry_date IS NULL ASC, p.expiry_date DESC',
        default => 'p.expiry_date IS NULL ASC, p.expiry_date ASC', // expiryAsc
    };

    // Count total matching items
    $countStmt = $db->prepare("SELECT COUNT(*) FROM products p {$whereClause}");
    $countStmt->execute($params);
    $total = (int)$countStmt->fetchColumn();

    // Fetch page of products
    $sql = "SELECT p.*,
            CASE 
                WHEN p.expiry_date IS NULL THEN NULL 
                ELSE DATEDIFF(p.expiry_date, CURDATE()) 
            END AS days_remaining
            FROM products p 
            {$whereClause} 
            ORDER BY {$orderBy} 
            LIMIT {$limit} OFFSET {$offset}";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $products = $stmt->fetchAll();

    // Format products
    $formatted = array_map(function ($p) {
        $p['reminder_enabled'] = (bool)$p['reminder_enabled'];
        $p['is_consumed'] = (bool)$p['is_consumed'];
        $p['is_favorite'] = (bool)$p['is_favorite'];
        $p['quantity'] = (float)$p['quantity'];
        $p['purchase_price'] = $p['purchase_price'] !== null ? (float)$p['purchase_price'] : 0.0;
        
        // Calculate status dynamically
        if ($p['expiry_date'] === null) {
            $p['calculated_status'] = 'No Expiry Date';
        } else {
            $days = (int)$p['days_remaining'];
            if ($days < 0) {
                $p['calculated_status'] = 'Expired';
            } elseif ($days <= 2) {
                $p['calculated_status'] = 'Expiring Soon';
            } else {
                $p['calculated_status'] = 'Safe';
            }
        }
        return $p;
    }, $products);

    json_response([
        'status' => 'success',
        'data' => $formatted,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => ceil($total / $limit),
        ],
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to fetch inventory products: ' . $e->getMessage(),
    ], 500);
}
