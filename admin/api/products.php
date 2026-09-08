<?php
/**
 * REST API - Products Endpoint
 * GET /api/products.php (List or lookup by ID/Barcode)
 * POST /api/products.php (Create new product)
 * PUT /api/products.php (Update product)
 * DELETE /api/products.php (Delete product)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];

// Handle preflight OPTIONS
if ($method === 'OPTIONS') {
    json_response(['status' => 'ok'], 200);
}

try {
    $db = Database::getConnection();

    if ($method === 'GET') {
        // Single product lookup by barcode or ID
        if (!empty($_GET['barcode'])) {
            $stmt = $db->prepare("SELECT * FROM products WHERE barcode = ? AND status != 'Archived' LIMIT 1");
            $stmt->execute([trim((string)$_GET['barcode'])]);
            $prod = $stmt->fetch();
            if ($prod) {
                json_response(['status' => 'success', 'data' => $prod]);
            } else {
                json_response(['status' => 'error', 'message' => 'Product not found for this barcode.'], 404);
            }
        }

        if (!empty($_GET['id'])) {
            $stmt = $db->prepare("SELECT * FROM products WHERE id = ? LIMIT 1");
            $stmt->execute([trim((string)$_GET['id'])]);
            $prod = $stmt->fetch();
            if ($prod) {
                json_response(['status' => 'success', 'data' => $prod]);
            } else {
                json_response(['status' => 'error', 'message' => 'Product not found.'], 404);
            }
        }

        // List products with filtering & pagination
        $search = trim((string)($_GET['search'] ?? $_GET['q'] ?? ''));
        $category = trim((string)($_GET['category'] ?? ''));
        $status = trim((string)($_GET['status'] ?? ''));
        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = max(1, min(100, (int)($_GET['limit'] ?? 50)));
        $offset = ($page - 1) * $limit;

        $where = ["status != 'Archived'"];
        $params = [];

        if ($search !== '') {
            $where[] = "(name LIKE ? OR brand LIKE ? OR barcode LIKE ? OR subcategory LIKE ?)";
            $like = "%{$search}%";
            $params = array_merge($params, [$like, $like, $like, $like]);
        }

        if ($category !== '') {
            $where[] = "category = ?";
            $params[] = $category;
        }

        if ($status !== '') {
            $where[] = "status = ?";
            $params[] = $status;
        }

        $whereSql = implode(' AND ', $where);

        $countStmt = $db->prepare("SELECT COUNT(*) FROM products WHERE {$whereSql}");
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $querySql = "SELECT * FROM products WHERE {$whereSql} ORDER BY created_at DESC LIMIT {$limit} OFFSET {$offset}";
        $stmt = $db->prepare($querySql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll();

        json_response([
            'status' => 'success',
            'data' => $rows,
            'meta' => [
                'total' => $total,
                'page' => $page,
                'limit' => $limit,
                'total_pages' => max(1, (int)ceil($total / $limit)),
            ]
        ]);
    }

    if ($method === 'POST') {
        $raw = file_get_contents('php://input');
        $input = !empty($raw) ? json_decode($raw, true) : $_POST;

        if (empty($input['name'])) {
            json_response(['status' => 'error', 'message' => 'Product name is required.'], 400);
        }

        $id = !empty($input['id']) ? trim((string)$input['id']) : 'prod-' . bin2hex(random_bytes(10));
        $userId = !empty($input['user_id']) ? trim((string)$input['user_id']) : 'default_user';
        $name = trim((string)$input['name']);
        $brand = !empty($input['brand']) ? trim((string)$input['brand']) : null;
        $barcode = !empty($input['barcode']) ? trim((string)$input['barcode']) : null;
        $category = !empty($input['category']) ? trim((string)$input['category']) : 'Other';
        $subcategory = !empty($input['subcategory']) ? trim((string)$input['subcategory']) : null;
        $quantity = isset($input['quantity']) ? (float)$input['quantity'] : 1.0;
        $unit = !empty($input['unit']) ? trim((string)$input['unit']) : 'pieces';
        $price = isset($input['purchase_price']) && $input['purchase_price'] !== '' ? (float)$input['purchase_price'] : null;
        $currency = !empty($input['currency']) ? trim((string)$input['currency']) : '₹';
        $expiryDate = !empty($input['expiry_date']) ? date('Y-m-d', strtotime((string)$input['expiry_date'])) : null;
        $imagePath = !empty($input['image_path']) ? trim((string)$input['image_path']) : null;
        $storageLocation = !empty($input['storage_location']) ? trim((string)$input['storage_location']) : 'pantry';

        $stmt = $db->prepare("
            INSERT INTO products (id, user_id, name, brand, barcode, category, subcategory, quantity, unit, purchase_price, currency, expiry_date, image_path, storage_location, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active')
            ON DUPLICATE KEY UPDATE name = VALUES(name), brand = VALUES(brand), category = VALUES(category), quantity = VALUES(quantity), purchase_price = VALUES(purchase_price), expiry_date = VALUES(expiry_date)
        ");
        $stmt->execute([$id, $userId, $name, $brand, $barcode, $category, $subcategory, $quantity, $unit, $price, $currency, $expiryDate, $imagePath, $storageLocation]);

        json_response(['status' => 'success', 'message' => 'Product saved successfully.', 'id' => $id], 201);
    }

    if ($method === 'DELETE') {
        $id = trim((string)($_GET['id'] ?? ''));
        if ($id === '') {
            json_response(['status' => 'error', 'message' => 'Product ID is required.'], 400);
        }

        $stmt = $db->prepare("DELETE FROM products WHERE id = ?");
        $stmt->execute([$id]);

        json_response(['status' => 'success', 'message' => 'Product deleted successfully.']);
    }

    json_response(['status' => 'error', 'message' => 'Method not allowed.'], 405);
} catch (Throwable $e) {
    json_response(['status' => 'error', 'message' => $e->getMessage()], 500);
}
