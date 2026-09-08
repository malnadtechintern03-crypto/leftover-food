<?php
/**
 * ScanSmart Reports & Business Intelligence Suite
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

$tab = trim((string)($_GET['tab'] ?? 'products'));
$startDate = trim((string)($_GET['start_date'] ?? ''));
$endDate = trim((string)($_GET['end_date'] ?? ''));

// CSV Export for Reports
if (isset($_GET['export']) && $_GET['export'] === 'csv') {
    if ($tab === 'expirations') {
        $stmt = $db->query("
            SELECT barcode, name, category, quantity, unit, storage_location, expiry_date,
                   DATEDIFF(expiry_date, CURDATE()) as days_remaining, expiry_status
            FROM products
            WHERE status != 'Archived' AND expiry_date IS NOT NULL
            ORDER BY expiry_date ASC
        ");
        $rows = $stmt->fetchAll();
        $headers = ['Barcode', 'Name', 'Category', 'Quantity', 'Unit', 'Location', 'Expiry Date', 'Days Left', 'Status'];
        export_to_csv('scansmart_expirations_' . date('Ymd') . '.csv', $headers, $rows);
    } elseif ($tab === 'scans') {
        $stmt = $db->query("
            SELECT id, user_id, barcode, scan_type, product_found, product_name, scan_date, scan_time
            FROM scan_history
            ORDER BY scan_date DESC, scan_time DESC
        ");
        $rows = $stmt->fetchAll();
        $headers = ['Scan ID', 'User ID', 'Barcode', 'Scan Type', 'Found', 'Product Name', 'Date', 'Time'];
        export_to_csv('scansmart_scans_' . date('Ymd') . '.csv', $headers, $rows);
    } elseif ($tab === 'categories') {
        $stmt = $db->query("
            SELECT c.name, COUNT(p.id) as product_count, SUM(p.quantity) as total_quantity
            FROM categories c
            LEFT JOIN products p ON (p.category_id = c.id OR p.category = c.name) AND p.status != 'Archived'
            GROUP BY c.id, c.name
            ORDER BY product_count DESC
        ");
        $rows = $stmt->fetchAll();
        $headers = ['Category', 'Cataloged Products Count', 'Total Stock Quantity'];
        export_to_csv('scansmart_categories_' . date('Ymd') . '.csv', $headers, $rows);
    } else {
        // Default: products
        $stmt = $db->query("
            SELECT barcode, name, brand, category, subcategory, quantity, unit, purchase_price, currency, expiry_date, status, created_at
            FROM products
            WHERE status != 'Archived'
            ORDER BY created_at DESC
        ");
        $rows = $stmt->fetchAll();
        $headers = ['Barcode', 'Name', 'Brand', 'Category', 'Subcategory', 'Quantity', 'Unit', 'Price', 'Currency', 'Expiry Date', 'Status', 'Added On'];
        export_to_csv('scansmart_products_' . date('Ymd') . '.csv', $headers, $rows);
    }
}

// Aggregation Queries
$totalProds = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived'")->fetchColumn();
$totalValuation = (float)$db->query("SELECT SUM(quantity * COALESCE(purchase_price, 0)) FROM products WHERE status != 'Archived'")->fetchColumn();
$expiredCount = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date < CURDATE()")->fetchColumn();
$expiringWeekCount = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date >= CURDATE() AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)")->fetchColumn();
$totalScans = (int)$db->query("SELECT COUNT(*) FROM scan_history")->fetchColumn();
$unknownScans = (int)$db->query("SELECT COUNT(*) FROM scan_history WHERE product_found = 0")->fetchColumn();

// Tab Data
if ($tab === 'expirations') {
    $reportItems = $db->query("
        SELECT name, brand, barcode, category, quantity, unit, expiry_date,
               DATEDIFF(expiry_date, CURDATE()) as days_remaining, expiry_status, storage_location
        FROM products
        WHERE status != 'Archived' AND expiry_date IS NOT NULL
        ORDER BY expiry_date ASC
        LIMIT 100
    ")->fetchAll();
} elseif ($tab === 'scans') {
    $reportItems = $db->query("
        SELECT s.*, COALESCE(p.name, s.product_name, 'Uncataloged') as display_name
        FROM scan_history s
        LEFT JOIN products p ON p.barcode = s.barcode
        ORDER BY s.scan_date DESC, s.scan_time DESC
        LIMIT 100
    ")->fetchAll();
} elseif ($tab === 'categories') {
    $reportItems = $db->query("
        SELECT c.name, c.icon, c.color, COUNT(p.id) as product_count,
               SUM(p.quantity) as total_qty, SUM(p.quantity * COALESCE(p.purchase_price, 0)) as cat_valuation
        FROM categories c
        LEFT JOIN products p ON (p.category_id = c.id OR p.category = c.name) AND p.status != 'Archived'
        GROUP BY c.id, c.name, c.icon, c.color
        ORDER BY product_count DESC
    ")->fetchAll();
} elseif ($tab === 'users') {
    $reportItems = $db->query("
        SELECT u.*,
               (SELECT COUNT(*) FROM products WHERE user_id = u.id AND status != 'Archived') as prod_count,
               (SELECT COUNT(*) FROM scan_history WHERE user_id = u.id) as scan_count
        FROM users u
        ORDER BY u.created_at DESC
        LIMIT 100
    ")->fetchAll();
} else {
    // Products tab
    $reportItems = $db->query("
        SELECT id, name, brand, barcode, category, quantity, unit, purchase_price, currency, expiry_date, status, created_at
        FROM products
        WHERE status != 'Archived'
        ORDER BY created_at DESC
        LIMIT 100
    ")->fetchAll();
}

$pageTitle = 'Reports & Intelligence';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Reports & Analytics Telemetry</h2>
    <p class="text-muted small mb-0">Generate inventory audits, expiration risk breakdowns, and scan activity logs.</p>
  </div>
  <div class="d-flex gap-2">
    <a href="<?= base_url('reports.php?tab=' . urlencode($tab) . '&export=csv') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-5">download</span>
      <span>Export CSV</span>
    </a>
    <button type="button" onclick="window.print()" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-5">print</span>
      <span>Print Report</span>
    </button>
  </div>
</div>

<!-- KPI Summary Cards -->
<div class="row g-3 mb-4">
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #ECFDF5; color: #10B981;"><span class="material-symbols-rounded">inventory_2</span></div>
      <div>
        <div class="card-stat-val"><?= number_format($totalProds) ?></div>
        <div class="card-stat-lbl">Cataloged Products</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #EFF6FF; color: #3B82F6;"><span class="material-symbols-rounded">payments</span></div>
      <div>
        <div class="card-stat-val">₹<?= number_format($totalValuation, 2) ?></div>
        <div class="card-stat-lbl">Inventory Value</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FEF2F2; color: #DC2626;"><span class="material-symbols-rounded">crisis_alert</span></div>
      <div>
        <div class="card-stat-val text-danger"><?= number_format($expiredCount) ?></div>
        <div class="card-stat-lbl">Expired Stock</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FFF7ED; color: #EA580C;"><span class="material-symbols-rounded">alarm</span></div>
      <div>
        <div class="card-stat-val" style="color: #EA580C;"><?= number_format($expiringWeekCount) ?></div>
        <div class="card-stat-lbl">Expiring in 7 Days</div>
      </div>
    </div>
  </div>
</div>

<!-- Navigation Tabs -->
<ul class="nav nav-pills mb-4 gap-2">
  <li class="nav-item">
    <a class="nav-link rounded-pill px-3 py-1.5 fw-semibold <?= $tab === 'products' ? 'active' : 'bg-white border text-dark' ?>" href="<?= base_url('reports.php?tab=products') ?>" style="<?= $tab === 'products' ? 'background-color: #10B981;' : '' ?>">
      Products Report
    </a>
  </li>
  <li class="nav-item">
    <a class="nav-link rounded-pill px-3 py-1.5 fw-semibold <?= $tab === 'expirations' ? 'active' : 'bg-white border text-dark' ?>" href="<?= base_url('reports.php?tab=expirations') ?>" style="<?= $tab === 'expirations' ? 'background-color: #10B981;' : '' ?>">
      Expirations & Waste Risk
    </a>
  </li>
  <li class="nav-item">
    <a class="nav-link rounded-pill px-3 py-1.5 fw-semibold <?= $tab === 'categories' ? 'active' : 'bg-white border text-dark' ?>" href="<?= base_url('reports.php?tab=categories') ?>" style="<?= $tab === 'categories' ? 'background-color: #10B981;' : '' ?>">
      Category Valuation
    </a>
  </li>
  <li class="nav-item">
    <a class="nav-link rounded-pill px-3 py-1.5 fw-semibold <?= $tab === 'scans' ? 'active' : 'bg-white border text-dark' ?>" href="<?= base_url('reports.php?tab=scans') ?>" style="<?= $tab === 'scans' ? 'background-color: #10B981;' : '' ?>">
      Mobile Scans Audit
    </a>
  </li>
  <li class="nav-item">
    <a class="nav-link rounded-pill px-3 py-1.5 fw-semibold <?= $tab === 'users' ? 'active' : 'bg-white border text-dark' ?>" href="<?= base_url('reports.php?tab=users') ?>" style="<?= $tab === 'users' ? 'background-color: #10B981;' : '' ?>">
      User Activity
    </a>
  </li>
</ul>

<!-- Report Table Output -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <?php if ($tab === 'expirations'): ?>
          <tr>
            <th>Product</th>
            <th>Barcode</th>
            <th>Category</th>
            <th>Location</th>
            <th>Expiry Date</th>
            <th>Days Remaining</th>
            <th>Status</th>
          </tr>
        <?php elseif ($tab === 'categories'): ?>
          <tr>
            <th>Category</th>
            <th>Products Cataloged</th>
            <th>Total Stock Items</th>
            <th>Total Estimated Valuation</th>
          </tr>
        <?php elseif ($tab === 'scans'): ?>
          <tr>
            <th>Scan ID</th>
            <th>Barcode</th>
            <th>Recognized Item</th>
            <th>Scan Type</th>
            <th>User</th>
            <th>Date & Time</th>
          </tr>
        <?php elseif ($tab === 'users'): ?>
          <tr>
            <th>User Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Status</th>
            <th>Saved Products</th>
            <th>Recorded Scans</th>
            <th>Joined On</th>
          </tr>
        <?php else: ?>
          <tr>
            <th>Product & Brand</th>
            <th>Barcode</th>
            <th>Category</th>
            <th>Quantity</th>
            <th>Unit Price</th>
            <th>Expiry Date</th>
            <th>Status</th>
          </tr>
        <?php endif; ?>
      </thead>
      <tbody>
        <?php if (empty($reportItems)): ?>
          <tr><td colspan="7" class="text-center py-5 text-muted">No data records found for this report.</td></tr>
        <?php else: ?>
          <?php foreach ($reportItems as $r): ?>
            <?php if ($tab === 'expirations'): 
              $d = (int)$r['days_remaining'];
            ?>
              <tr>
                <td class="fw-bold"><?= e($r['name']) ?></td>
                <td><span class="barcode-pill"><?= e($r['barcode'] ?: '—') ?></span></td>
                <td><span class="badge bg-light text-dark rounded-pill border"><?= e($r['category']) ?></span></td>
                <td><?= e(ucfirst($r['storage_location'] ?? 'pantry')) ?></td>
                <td class="fw-bold text-danger"><?= format_date($r['expiry_date']) ?></td>
                <td>
                  <?php if ($d < 0): ?>
                    <span class="text-danger fw-bold"><?= abs($d) ?>d overdue</span>
                  <?php elseif ($d <= 7): ?>
                    <span class="text-warning fw-bold"><?= $d ?>d left</span>
                  <?php else: ?>
                    <span class="text-success"><?= $d ?>d left</span>
                  <?php endif; ?>
                </td>
                <td><span class="badge-status <?= strtolower(str_replace(' ', '-', $r['expiry_status'])) ?>"><?= e($r['expiry_status']) ?></span></td>
              </tr>
            <?php elseif ($tab === 'categories'): ?>
              <tr>
                <td class="fw-bold text-dark">
                  <span class="material-symbols-rounded me-1 align-middle" style="color: <?= e($r['color'] ?: '#10B981') ?>;"><?= e($r['icon'] ?: 'category') ?></span>
                  <?= e($r['name']) ?>
                </td>
                <td><?= number_format((int)$r['product_count']) ?> items</td>
                <td><?= number_format((float)($r['total_qty'] ?? 0), 2) ?></td>
                <td class="fw-bold text-success">₹<?= number_format((float)($r['cat_valuation'] ?? 0), 2) ?></td>
              </tr>
            <?php elseif ($tab === 'scans'): ?>
              <tr>
                <td><code>#<?= $r['id'] ?></code></td>
                <td><span class="barcode-pill"><?= e($r['barcode'] ?: '—') ?></span></td>
                <td class="fw-bold"><?= e($r['display_name']) ?></td>
                <td><span class="badge bg-light text-dark rounded-pill border"><?= e($r['scan_type']) ?></span></td>
                <td><code><?= e($r['user_id']) ?></code></td>
                <td class="text-muted"><?= format_date($r['scan_date']) ?> <?= substr($r['scan_time'], 0, 5) ?></td>
              </tr>
            <?php elseif ($tab === 'users'): ?>
              <tr>
                <td class="fw-bold"><?= e($r['name']) ?></td>
                <td><?= e($r['email']) ?></td>
                <td><span class="badge bg-light text-dark rounded-pill border"><?= e($r['role']) ?></span></td>
                <td><span class="badge-status <?= $r['status'] === 'active' ? 'active' : 'inactive' ?>"><?= e($r['status']) ?></span></td>
                <td><?= (int)$r['prod_count'] ?> products</td>
                <td><?= (int)$r['scan_count'] ?> scans</td>
                <td class="text-muted"><?= format_date($r['created_at']) ?></td>
              </tr>
            <?php else: ?>
              <tr>
                <td>
                  <div class="fw-bold text-dark"><?= e($r['name']) ?></div>
                  <div class="text-muted small"><?= e($r['brand'] ?: 'Generic') ?></div>
                </td>
                <td><?= !empty($r['barcode']) ? '<span class="barcode-pill">' . e($r['barcode']) . '</span>' : '—' ?></td>
                <td><span class="badge bg-light text-dark rounded-pill border"><?= e($r['category']) ?></span></td>
                <td><?= (float)$r['quantity'] ?> <?= e($r['unit']) ?></td>
                <td><?= e($r['currency'] ?? '₹') ?><?= number_format((float)($r['purchase_price'] ?? 0), 2) ?></td>
                <td><?= format_date($r['expiry_date']) ?></td>
                <td><span class="badge-status <?= strtolower(str_replace(' ', '-', $r['status'])) ?>"><?= e($r['status']) ?></span></td>
              </tr>
            <?php endif; ?>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
