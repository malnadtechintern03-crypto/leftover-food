<?php
/**
 * ScanSmart Inventory Management - Multi-User Stock Telemetry
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// Delete Inventory Record
if (isset($_GET['delete']) && can_edit_inventory()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } else {
        $invId = (int)$_GET['delete'];
        $db->prepare('DELETE FROM inventory WHERE id = ?')->execute([$invId]);
        log_admin_activity('Delete Inventory Record', "Removed inventory record #{$invId}");
        set_flash('success', 'Inventory record removed.');
    }
    header('Location: ' . base_url('inventory.php'));
    exit;
}

// Export Inventory to CSV
if (isset($_GET['export']) && $_GET['export'] === 'csv') {
    $expStmt = $db->query("
        SELECT i.id, i.user_id, p.name AS product_name, p.barcode, p.category, i.quantity, i.unit,
               i.purchase_price, i.purchase_date, i.expiry_date, i.storage_location, i.status, i.notes
        FROM inventory i
        JOIN products p ON p.id = i.product_id
        ORDER BY i.created_at DESC
    ");
    $rows = $expStmt->fetchAll();
    $headers = ['Inventory ID', 'User ID', 'Product', 'Barcode', 'Category', 'Quantity', 'Unit', 'Price', 'Purchase Date', 'Expiry Date', 'Location', 'Status', 'Notes'];
    log_admin_activity('Export Inventory CSV', 'Exported inventory list to CSV (' . count($rows) . ' records)');
    export_to_csv('scansmart_inventory_' . date('Ymd_His') . '.csv', $headers, $rows);
}

// Filters & Search
$search = trim((string)($_GET['q'] ?? ''));
$userFilter = trim((string)($_GET['user'] ?? ''));
$categoryFilter = trim((string)($_GET['category'] ?? ''));
$statusFilter = trim((string)($_GET['status'] ?? ''));

$where = [];
$params = [];

if ($search !== '') {
    $where[] = "(p.name LIKE ? OR p.brand LIKE ? OR p.barcode LIKE ? OR i.notes LIKE ?)";
    $like = "%{$search}%";
    $params = array_merge($params, [$like, $like, $like, $like]);
}

if ($userFilter !== '') {
    $where[] = "i.user_id = ?";
    $params[] = $userFilter;
}

if ($categoryFilter !== '') {
    $where[] = "p.category = ?";
    $params[] = $categoryFilter;
}

if ($statusFilter !== '') {
    $where[] = "i.status = ?";
    $params[] = $statusFilter;
}

$whereSql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

$stmt = $db->prepare("
    SELECT i.*, p.name AS product_name, p.brand, p.barcode, p.category, p.image_path,
           DATEDIFF(i.expiry_date, CURDATE()) AS days_remaining
    FROM inventory i
    JOIN products p ON p.id = i.product_id
    {$whereSql}
    ORDER BY i.created_at DESC
");
$stmt->execute($params);
$records = $stmt->fetchAll();

$userList = $db->query("SELECT DISTINCT user_id FROM inventory ORDER BY user_id ASC")->fetchAll(PDO::FETCH_COLUMN);
$catList = $db->query("SELECT name FROM categories WHERE status = 'active' ORDER BY name ASC")->fetchAll(PDO::FETCH_COLUMN);

$pageTitle = 'Inventory Management';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Inventory Management</h2>
    <p class="text-muted small mb-0">Multi-user live stock holdings, storage locations, purchase costs, and freshness.</p>
  </div>
  <div class="d-flex gap-2">
    <a href="<?= base_url('inventory.php?export=csv') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-5">download</span>
      <span>Export Inventory CSV</span>
    </a>
  </div>
</div>

<!-- Filters Bar -->
<div class="card border-0 shadow-sm rounded-4 mb-4 bg-white p-3 p-md-4">
  <form method="GET" action="" class="row g-2 align-items-end">
    <div class="col-md-4">
      <label for="q" class="form-label small fw-bold text-muted">Search Inventory</label>
      <input type="text" name="q" id="q" value="<?= e($search) ?>" class="form-control bg-light" placeholder="Product name, barcode, notes...">
    </div>

    <div class="col-6 col-md-3">
      <label for="category" class="form-label small fw-bold text-muted">Category</label>
      <select name="category" id="category" class="form-select bg-light">
        <option value="">All Categories</option>
        <?php foreach ($catList as $cat): ?>
          <option value="<?= e($cat) ?>" <?= $categoryFilter === $cat ? 'selected' : '' ?>><?= e($cat) ?></option>
        <?php endforeach; ?>
      </select>
    </div>

    <div class="col-6 col-md-2">
      <label for="user" class="form-label small fw-bold text-muted">User ID</label>
      <select name="user" id="user" class="form-select bg-light">
        <option value="">All Users</option>
        <?php foreach ($userList as $u): ?>
          <option value="<?= e($u) ?>" <?= $userFilter === $u ? 'selected' : '' ?>><?= e($u) ?></option>
        <?php endforeach; ?>
      </select>
    </div>

    <div class="col-6 col-md-2">
      <label for="status" class="form-label small fw-bold text-muted">Stock Status</label>
      <select name="status" id="status" class="form-select bg-light">
        <option value="">All Statuses</option>
        <option value="In Stock" <?= $statusFilter === 'In Stock' ? 'selected' : '' ?>>In Stock</option>
        <option value="Low Stock" <?= $statusFilter === 'Low Stock' ? 'selected' : '' ?>>Low Stock</option>
        <option value="Out of Stock" <?= $statusFilter === 'Out of Stock' ? 'selected' : '' ?>>Out of Stock</option>
      </select>
    </div>

    <div class="col-6 col-md-1 d-flex gap-1">
      <button type="submit" class="btn btn-primary w-100 fw-semibold" style="background-color: #10B981; border-color: #10B981;">Filter</button>
      <?php if ($search !== '' || $categoryFilter !== '' || $userFilter !== '' || $statusFilter !== ''): ?>
        <a href="<?= base_url('inventory.php') ?>" class="btn btn-light border" title="Reset"><span class="material-symbols-rounded fs-6">close</span></a>
      <?php endif; ?>
    </div>
  </form>
</div>

<!-- Table -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <tr>
          <th>User</th>
          <th>Product & Brand</th>
          <th>Barcode</th>
          <th>Category</th>
          <th>Quantity</th>
          <th>Storage Location</th>
          <th>Purchase Date & Cost</th>
          <th>Expiry Date</th>
          <th>Status</th>
          <th width="100" class="text-end">Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($records)): ?>
          <tr><td colspan="10" class="text-center py-5 text-muted">No inventory records match current filter.</td></tr>
        <?php else: ?>
          <?php foreach ($records as $row): 
            $days = $row['days_remaining'] !== null ? (int)$row['days_remaining'] : null;
          ?>
            <tr>
              <td><strong><?= e($row['user_id']) ?></strong></td>
              <td>
                <div class="fw-bold text-dark"><?= e($row['product_name']) ?></div>
                <div class="text-muted small"><?= e($row['brand'] ?: 'Generic') ?></div>
              </td>
              <td><?= !empty($row['barcode']) ? '<span class="barcode-pill">' . e($row['barcode']) . '</span>' : '<span class="text-muted">—</span>' ?></td>
              <td><span class="badge bg-light text-dark rounded-pill border"><?= e($row['category']) ?></span></td>
              <td class="fw-bold"><?= (float)$row['quantity'] ?> <?= e($row['unit']) ?></td>
              <td><span class="badge bg-secondary-subtle text-secondary rounded-pill"><?= e(ucfirst($row['storage_location'] ?? 'pantry')) ?></span></td>
              <td>
                <div><?= format_date($row['purchase_date']) ?></div>
                <div class="text-muted small"><?= $row['purchase_price'] !== null ? '₹' . number_format((float)$row['purchase_price'], 2) : '—' ?></div>
              </td>
              <td>
                <?php if ($row['expiry_date']): ?>
                  <div class="fw-semibold"><?= format_date($row['expiry_date']) ?></div>
                  <?php if ($days !== null && $days < 0): ?>
                    <span class="badge-status expired">Expired</span>
                  <?php elseif ($days !== null && $days <= 7): ?>
                    <span class="badge-status expiring-soon"><?= $days ?>d left</span>
                  <?php else: ?>
                    <span class="badge-status safe">Safe</span>
                  <?php endif; ?>
                <?php else: ?>
                  <span class="badge-status no-expiry">No Expiry</span>
                <?php endif; ?>
              </td>
              <td>
                <span class="badge-status <?= $row['status'] === 'In Stock' ? 'active' : ($row['status'] === 'Low Stock' ? 'expiring-soon' : 'inactive') ?>">
                  <?= e($row['status']) ?>
                </span>
              </td>
              <td class="text-end">
                <?php if (can_edit_inventory()): ?>
                  <a href="<?= base_url('inventory.php?delete=' . (int)$row['id'] . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-sm btn-light border text-danger py-1 px-2 rounded-2" title="Remove Stock Record" onclick="return confirm('Remove this inventory record?');">
                    <span class="material-symbols-rounded" style="font-size: 16px;">delete</span>
                  </a>
                <?php endif; ?>
              </td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
