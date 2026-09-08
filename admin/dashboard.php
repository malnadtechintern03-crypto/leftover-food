<?php
/**
 * ScanSmart Admin Panel - Overview Dashboard
 * Loads 100% Real MySQL Data & Interactive Visualizations
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// =========================================================================
// 1. ALL 12 REAL MYSQL METRIC CARDS
// =========================================================================
$totalProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived'")->fetchColumn();
$totalCategories = (int)$db->query("SELECT COUNT(*) FROM categories WHERE status = 'active'")->fetchColumn();
$totalUsers = (int)$db->query("SELECT COUNT(*) FROM users")->fetchColumn();
$totalScans = (int)$db->query("SELECT COUNT(*) FROM scan_history")->fetchColumn();
$totalInventory = (int)$db->query("SELECT COUNT(*) FROM inventory WHERE status = 'In Stock'")->fetchColumn();

// Expiration statistics
$expiringToday = (int)$db->query("SELECT COUNT(*) FROM products WHERE status = 'Active' AND is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date = CURDATE()")->fetchColumn();
$expiringWithin7 = (int)$db->query("SELECT COUNT(*) FROM products WHERE status = 'Active' AND is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date > CURDATE() AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)")->fetchColumn();
$expiringWithin30 = (int)$db->query("SELECT COUNT(*) FROM products WHERE status = 'Active' AND is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date > DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)")->fetchColumn();
$expiredProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE status = 'Active' AND is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date < CURDATE()")->fetchColumn();
$noExpiryProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE status = 'Active' AND is_consumed = 0 AND expiry_date IS NULL")->fetchColumn();

// Review queues
$unknownProductsCount = (int)$db->query("SELECT COUNT(*) FROM unknown_products WHERE review_status = 'Pending Review'")->fetchColumn();
$productsNeedingReview = (int)$db->query("SELECT COUNT(*) FROM products WHERE review_status IN ('Pending Review', 'Needs Correction') OR status = 'Pending Review'")->fetchColumn();

// Safe count
$safeCount = (int)$db->query("SELECT COUNT(*) FROM products WHERE status = 'Active' AND is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date > DATE_ADD(CURDATE(), INTERVAL 7 DAY)")->fetchColumn();

// =========================================================================
// 2. DASHBOARD DATA SECTIONS
// =========================================================================

// Section 1: Recent Scans (5 rows)
$scansStmt = $db->query("
    SELECT s.*, COALESCE(p.name, s.product_name, 'Uncataloged Item') AS display_name
    FROM scan_history s
    LEFT JOIN products p ON p.barcode = s.barcode
    ORDER BY s.scan_date DESC, s.scan_time DESC, s.id DESC
    LIMIT 5
");
$recentScans = $scansStmt->fetchAll();

// Section 2: Recently Added Products (5 rows)
$recentProductsStmt = $db->query("
    SELECT id, name, brand, barcode, category, purchase_price, currency, status, created_at, image_path
    FROM products
    ORDER BY created_at DESC
    LIMIT 5
");
$recentProducts = $recentProductsStmt->fetchAll();

// Section 3: Expiring Products (5 rows)
$expiringStmt = $db->query("
    SELECT id, name, brand, barcode, category, expiry_date, DATEDIFF(expiry_date, CURDATE()) AS days_remaining
    FROM products
    WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date >= CURDATE()
    ORDER BY expiry_date ASC
    LIMIT 5
");
$recentExpiring = $expiringStmt->fetchAll();

// Section 4: Expired Products (5 rows)
$expiredStmt = $db->query("
    SELECT id, name, brand, barcode, category, expiry_date, DATEDIFF(CURDATE(), expiry_date) AS days_overdue
    FROM products
    WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date < CURDATE()
    ORDER BY expiry_date DESC
    LIMIT 5
");
$recentExpired = $expiredStmt->fetchAll();

// Section 5: Products by Category (Category stats + Chart Data)
$catStatsStmt = $db->query("
    SELECT c.name, c.color, COUNT(p.id) AS prod_count
    FROM categories c
    LEFT JOIN products p ON (p.category_id = c.id OR p.category = c.name) AND p.status != 'Archived'
    GROUP BY c.id, c.name, c.color
    ORDER BY prod_count DESC
");
$catStats = $catStatsStmt->fetchAll();

$chartCatLabels = [];
$chartCatCounts = [];
$chartCatColors = [];
foreach ($catStats as $cs) {
    if ((int)$cs['prod_count'] > 0) {
        $chartCatLabels[] = $cs['name'];
        $chartCatCounts[] = (int)$cs['prod_count'];
        $chartCatColors[] = $cs['color'] ?: '#10B981';
    }
}
// Fallback if empty
if (empty($chartCatLabels)) {
    $chartCatLabels = ['General'];
    $chartCatCounts = [$totalProducts];
    $chartCatColors = ['#10B981'];
}

// Section 6: Unknown Product Requests (5 rows)
$unknownStmt = $db->query("
    SELECT id, barcode, product_name, ocr_text, user_id, scan_type, review_status, created_at
    FROM unknown_products
    ORDER BY created_at DESC
    LIMIT 5
");
$recentUnknown = $unknownStmt->fetchAll();

// Section 7: Recent Admin Activity Logs (5 rows)
$logsStmt = $db->query("
    SELECT admin_name, action, description, ip_address, created_at
    FROM admin_activity_logs
    ORDER BY id DESC
    LIMIT 5
");
$recentLogs = $logsStmt->fetchAll();

// Monthly Scans Data (Last 6 months)
$scansTrendStmt = $db->query("
    SELECT DATE_FORMAT(scan_date, '%b %Y') as month_label, COUNT(*) as scan_count
    FROM scan_history
    WHERE scan_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    GROUP BY month_label, DATE_FORMAT(scan_date, '%Y-%m')
    ORDER BY DATE_FORMAT(scan_date, '%Y-%m') ASC
");
$scansTrend = $scansTrendStmt->fetchAll();
$chartScansLabels = [];
$chartScansCounts = [];
foreach ($scansTrend as $st) {
    $chartScansLabels[] = $st['month_label'];
    $chartScansCounts[] = (int)$st['scan_count'];
}
if (empty($chartScansLabels)) {
    $chartScansLabels = [date('M Y')];
    $chartScansCounts = [$totalScans];
}

$pageTitle = 'Admin Dashboard';
require_once __DIR__ . '/includes/header.php';
?>

<!-- Brand Welcome Banner -->
<div class="card border-0 text-white rounded-4 p-4 mb-4 shadow-sm" style="background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%);">
  <div class="row align-items-center">
    <div class="col-lg-8 mb-3 mb-lg-0">
      <span class="badge px-3 py-1.5 rounded-pill mb-2 fw-bold" style="background: #10B981; font-size: 11.5px;">
        ScanSmart Universal Inventory
      </span>
      <h2 class="fw-bold mb-1" style="font-size: 22px;">Welcome back, <?= e($currentAdmin['name']) ?>! 👋</h2>
      <p class="text-white-50 mb-0 small">
        “Scan Anything. Know Everything. Never Miss an Expiry.” Here is your real-time catalog and expiration telemetry.
      </p>
    </div>
    <div class="col-lg-4 text-lg-end d-flex flex-wrap gap-2 justify-content-lg-end">
      <a href="<?= base_url('product-add.php') ?>" class="btn btn-sm btn-primary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1" style="background-color: #10B981; border-color: #10B981;">
        <span class="material-symbols-rounded fs-6">add</span>
        <span>Add Product</span>
      </a>
      <a href="<?= base_url('expiration-alerts.php') ?>" class="btn btn-sm btn-outline-light rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">notifications_active</span>
        <span>Expiry Alerts</span>
      </a>
    </div>
  </div>
</div>

<!-- =======================================================================
     12 REAL METRIC CARDS GRID
     ======================================================================= -->
<div class="row g-3 mb-4">
  <!-- 1. Total Products -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #ECFDF5; color: #10B981;">
        <span class="material-symbols-rounded">inventory_2</span>
      </div>
      <div>
        <div class="card-stat-val"><?= number_format($totalProducts) ?></div>
        <div class="card-stat-lbl">Total Products</div>
      </div>
    </div>
  </div>

  <!-- 2. Total Categories -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #EFF6FF; color: #3B82F6;">
        <span class="material-symbols-rounded">category</span>
      </div>
      <div>
        <div class="card-stat-val"><?= number_format($totalCategories) ?></div>
        <div class="card-stat-lbl">Categories</div>
      </div>
    </div>
  </div>

  <!-- 3. Total Users -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #F5F3FF; color: #8B5CF6;">
        <span class="material-symbols-rounded">people</span>
      </div>
      <div>
        <div class="card-stat-val"><?= number_format($totalUsers) ?></div>
        <div class="card-stat-lbl">Total Users</div>
      </div>
    </div>
  </div>

  <!-- 4. Total Scans -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #ECFEFF; color: #06B6D4;">
        <span class="material-symbols-rounded">qr_code_scanner</span>
      </div>
      <div>
        <div class="card-stat-val"><?= number_format($totalScans) ?></div>
        <div class="card-stat-lbl">Total Scans</div>
      </div>
    </div>
  </div>

  <!-- 5. Total Inventory Records -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FFFBEB; color: #F59E0B;">
        <span class="material-symbols-rounded">shelves</span>
      </div>
      <div>
        <div class="card-stat-val"><?= number_format($totalInventory) ?></div>
        <div class="card-stat-lbl">In Stock</div>
      </div>
    </div>
  </div>

  <!-- 6. Expiring Today -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern" style="<?= $expiringToday > 0 ? 'border-color: #F87171;' : '' ?>">
      <div class="card-stat-icon" style="background: #FEF2F2; color: #EF4444;">
        <span class="material-symbols-rounded">crisis_alert</span>
      </div>
      <div>
        <div class="card-stat-val text-danger"><?= number_format($expiringToday) ?></div>
        <div class="card-stat-lbl">Expiring Today</div>
      </div>
    </div>
  </div>

  <!-- 7. Expiring <= 7 Days -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FFF7ED; color: #EA580C;">
        <span class="material-symbols-rounded">alarm</span>
      </div>
      <div>
        <div class="card-stat-val" style="color: #EA580C;"><?= number_format($expiringWithin7) ?></div>
        <div class="card-stat-lbl">&le; 7 Days</div>
      </div>
    </div>
  </div>

  <!-- 8. Expiring <= 30 Days -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FEF3C7; color: #D97706;">
        <span class="material-symbols-rounded">calendar_month</span>
      </div>
      <div>
        <div class="card-stat-val" style="color: #D97706;"><?= number_format($expiringWithin30) ?></div>
        <div class="card-stat-lbl">&le; 30 Days</div>
      </div>
    </div>
  </div>

  <!-- 9. Expired Products -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FEE2E2; color: #DC2626;">
        <span class="material-symbols-rounded">error</span>
      </div>
      <div>
        <div class="card-stat-val text-danger"><?= number_format($expiredProducts) ?></div>
        <div class="card-stat-lbl">Expired</div>
      </div>
    </div>
  </div>

  <!-- 10. Without Expiry Dates -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #F1F5F9; color: #64748B;">
        <span class="material-symbols-rounded">event_busy</span>
      </div>
      <div>
        <div class="card-stat-val text-muted"><?= number_format($noExpiryProducts) ?></div>
        <div class="card-stat-lbl">No Expiry Date</div>
      </div>
    </div>
  </div>

  <!-- 11. Unknown Products -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FEF9C3; color: #CA8A04;">
        <span class="material-symbols-rounded">help_center</span>
      </div>
      <div>
        <div class="card-stat-val" style="color: #CA8A04;"><?= number_format($unknownProductsCount) ?></div>
        <div class="card-stat-lbl">Unknown Scans</div>
      </div>
    </div>
  </div>

  <!-- 12. Needing Review -->
  <div class="col-6 col-md-4 col-xl-2">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FCE7F3; color: #DB2777;">
        <span class="material-symbols-rounded">rate_review</span>
      </div>
      <div>
        <div class="card-stat-val" style="color: #DB2777;"><?= number_format($productsNeedingReview) ?></div>
        <div class="card-stat-lbl">Needs Review</div>
      </div>
    </div>
  </div>
</div>

<!-- =======================================================================
     INTERACTIVE ANALYTICS CHARTS
     ======================================================================= -->
<div class="row g-4 mb-4">
  <div class="col-lg-4">
    <div class="card border-0 shadow-sm rounded-4 h-100 p-4 bg-white">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h3 class="h6 fw-bold mb-0">Products by Category</h3>
        <span class="badge bg-light text-muted small rounded-pill">Catalog Distribution</span>
      </div>
      <div style="height: 240px; position: relative;">
        <canvas id="chartProductsByCategory"></canvas>
      </div>
    </div>
  </div>

  <div class="col-lg-4">
    <div class="card border-0 shadow-sm rounded-4 h-100 p-4 bg-white">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h3 class="h6 fw-bold mb-0">Monthly Mobile Scans</h3>
        <span class="badge bg-light text-muted small rounded-pill">Recent Activity</span>
      </div>
      <div style="height: 240px; position: relative;">
        <canvas id="chartMonthlyScans"></canvas>
      </div>
    </div>
  </div>

  <div class="col-lg-4">
    <div class="card border-0 shadow-sm rounded-4 h-100 p-4 bg-white">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h3 class="h6 fw-bold mb-0">Expiration Distribution</h3>
        <span class="badge bg-light text-muted small rounded-pill">Freshness Telemetry</span>
      </div>
      <div style="height: 240px; position: relative;">
        <canvas id="chartExpiryDistribution"></canvas>
      </div>
    </div>
  </div>
</div>

<!-- =======================================================================
     DASHBOARD SECTIONS: 1 TO 7
     ======================================================================= -->
<div class="row g-4">
  <!-- Section 1 & 2: Recent Scans & Recently Added Products -->
  <div class="col-lg-6">
    <!-- Section 1: Recent Scans -->
    <div class="card border-0 shadow-sm rounded-4 mb-4 bg-white overflow-hidden">
      <div class="p-3 px-4 border-bottom d-flex justify-content-between align-items-center">
        <div class="d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-primary fs-5">history</span>
          <h4 class="h6 fw-bold mb-0">1. Recent Mobile Scans</h4>
        </div>
        <a href="<?= base_url('scan-history.php') ?>" class="text-decoration-none small fw-semibold text-primary">View All</a>
      </div>
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
          <thead class="table-light">
            <tr>
              <th>Barcode</th>
              <th>Product</th>
              <th>Type</th>
              <th>Result</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($recentScans)): ?>
              <tr><td colspan="5" class="text-center py-4 text-muted">No mobile scan activity recorded yet.</td></tr>
            <?php else: ?>
              <?php foreach ($recentScans as $scan): ?>
                <tr>
                  <td><span class="barcode-pill"><?= e($scan['barcode'] ?: 'N/A') ?></span></td>
                  <td class="fw-semibold text-truncate" style="max-width: 140px;"><?= e($scan['display_name']) ?></td>
                  <td><span class="badge bg-light text-dark rounded-pill"><?= e($scan['scan_type']) ?></span></td>
                  <td>
                    <?php if ((int)$scan['product_found'] === 1): ?>
                      <span class="badge bg-success-subtle text-success rounded-pill">Found</span>
                    <?php else: ?>
                      <span class="badge bg-warning-subtle text-warning rounded-pill">Not Found</span>
                    <?php endif; ?>
                  </td>
                  <td class="text-muted" style="font-size: 11.5px;"><?= e($scan['scan_date']) ?> <?= substr($scan['scan_time'], 0, 5) ?></td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Section 2: Recently Added Products -->
    <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden">
      <div class="p-3 px-4 border-bottom d-flex justify-content-between align-items-center">
        <div class="d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-success fs-5">add_shopping_cart</span>
          <h4 class="h6 fw-bold mb-0">2. Recently Added Products</h4>
        </div>
        <a href="<?= base_url('products.php') ?>" class="text-decoration-none small fw-semibold text-success">Manage All</a>
      </div>
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
          <thead class="table-light">
            <tr>
              <th>Product</th>
              <th>Category</th>
              <th>Price</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($recentProducts)): ?>
              <tr><td colspan="5" class="text-center py-4 text-muted">No products cataloged yet.</td></tr>
            <?php else: ?>
              <?php foreach ($recentProducts as $prod): ?>
                <tr>
                  <td>
                    <div class="d-flex align-items-center gap-2">
                      <?php if (!empty($prod['image_path'])): ?>
                        <img src="<?= e($prod['image_path']) ?>" class="rounded-2" style="width: 32px; height: 32px; object-fit: cover;" onerror="this.style.display='none'">
                      <?php else: ?>
                        <div class="bg-light rounded-2 d-flex align-items-center justify-content-center text-muted" style="width: 32px; height: 32px;"><span class="material-symbols-rounded" style="font-size: 18px;">image</span></div>
                      <?php endif; ?>
                      <div>
                        <div class="fw-bold text-truncate" style="max-width: 130px;"><?= e($prod['name']) ?></div>
                        <div class="text-muted" style="font-size: 11px;"><?= e($prod['barcode'] ?: 'No Barcode') ?></div>
                      </div>
                    </div>
                  </td>
                  <td><span class="badge bg-light text-dark rounded-pill"><?= e($prod['category']) ?></span></td>
                  <td class="fw-semibold"><?= e($prod['currency'] ?? '₹') ?><?= number_format((float)($prod['purchase_price'] ?? 0), 2) ?></td>
                  <td><span class="badge-status <?= strtolower(str_replace(' ', '-', $prod['status'])) ?>"><?= e($prod['status']) ?></span></td>
                  <td>
                    <a href="<?= base_url('product-view.php?id=' . urlencode($prod['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="View"><span class="material-symbols-rounded" style="font-size: 16px;">visibility</span></a>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Section 3 & 4: Expiring & Expired Products -->
  <div class="col-lg-6">
    <!-- Section 3: Expiring Products -->
    <div class="card border-0 shadow-sm rounded-4 mb-4 bg-white overflow-hidden">
      <div class="p-3 px-4 border-bottom d-flex justify-content-between align-items-center">
        <div class="d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-warning fs-5">warning</span>
          <h4 class="h6 fw-bold mb-0">3. Expiring Soon Products (&le; 7 Days)</h4>
        </div>
        <a href="<?= base_url('expiration-alerts.php?filter=expiring_soon') ?>" class="text-decoration-none small fw-semibold text-warning">View All</a>
      </div>
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
          <thead class="table-light">
            <tr>
              <th>Product</th>
              <th>Category</th>
              <th>Expiry Date</th>
              <th>Time Left</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($recentExpiring)): ?>
              <tr><td colspan="5" class="text-center py-4 text-muted">🎉 Great job! No products expiring in the next 7 days.</td></tr>
            <?php else: ?>
              <?php foreach ($recentExpiring as $item): 
                $days = (int)$item['days_remaining'];
              ?>
                <tr>
                  <td class="fw-semibold text-truncate" style="max-width: 140px;"><?= e($item['name']) ?></td>
                  <td><span class="badge bg-light text-dark rounded-pill"><?= e($item['category']) ?></span></td>
                  <td><?= format_date($item['expiry_date']) ?></td>
                  <td>
                    <?php if ($days === 0): ?>
                      <span class="badge bg-danger rounded-pill">Today!</span>
                    <?php elseif ($days === 1): ?>
                      <span class="badge bg-danger-subtle text-danger rounded-pill">Tomorrow</span>
                    <?php else: ?>
                      <span class="badge bg-warning-subtle text-warning rounded-pill"><?= $days ?> days left</span>
                    <?php endif; ?>
                  </td>
                  <td>
                    <a href="<?= base_url('product-edit.php?id=' . urlencode($item['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="Edit Expiry"><span class="material-symbols-rounded" style="font-size: 16px;">edit</span></a>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Section 4: Expired Products -->
    <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden">
      <div class="p-3 px-4 border-bottom d-flex justify-content-between align-items-center">
        <div class="d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-danger fs-5">error</span>
          <h4 class="h6 fw-bold mb-0">4. Expired Products Queue</h4>
        </div>
        <a href="<?= base_url('expiration-alerts.php?filter=expired') ?>" class="text-decoration-none small fw-semibold text-danger">View All</a>
      </div>
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
          <thead class="table-light">
            <tr>
              <th>Product</th>
              <th>Category</th>
              <th>Expired Date</th>
              <th>Overdue</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($recentExpired)): ?>
              <tr><td colspan="5" class="text-center py-4 text-muted">No expired products in inventory.</td></tr>
            <?php else: ?>
              <?php foreach ($recentExpired as $exp): ?>
                <tr>
                  <td class="fw-semibold text-truncate" style="max-width: 140px;"><?= e($exp['name']) ?></td>
                  <td><span class="badge bg-light text-dark rounded-pill"><?= e($exp['category']) ?></span></td>
                  <td class="text-danger"><?= format_date($exp['expiry_date']) ?></td>
                  <td><span class="badge bg-danger-subtle text-danger rounded-pill"><?= (int)$exp['days_overdue'] ?>d ago</span></td>
                  <td>
                    <a href="<?= base_url('product-edit.php?id=' . urlencode($exp['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="Update"><span class="material-symbols-rounded" style="font-size: 16px;">edit</span></a>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<!-- Section 6 & 7: Unknown Products & Recent Admin Activity -->
<div class="row g-4 mt-1">
  <!-- Section 6: Unknown Product Requests -->
  <div class="col-lg-6">
    <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden h-100">
      <div class="p-3 px-4 border-bottom d-flex justify-content-between align-items-center">
        <div class="d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-warning fs-5">help_center</span>
          <h4 class="h6 fw-bold mb-0">6. Unknown Product Requests</h4>
        </div>
        <a href="<?= base_url('unknown-products.php') ?>" class="text-decoration-none small fw-semibold text-warning">Triage All</a>
      </div>
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
          <thead class="table-light">
            <tr>
              <th>Barcode</th>
              <th>Suggested Name</th>
              <th>Type</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($recentUnknown)): ?>
              <tr><td colspan="5" class="text-center py-4 text-muted">All scanned barcodes are currently cataloged.</td></tr>
            <?php else: ?>
              <?php foreach ($recentUnknown as $un): ?>
                <tr>
                  <td><span class="barcode-pill"><?= e($un['barcode']) ?></span></td>
                  <td class="fw-semibold text-truncate" style="max-width: 140px;"><?= e($un['product_name'] ?: ($un['ocr_text'] ? substr($un['ocr_text'], 0, 30) : 'Unlabeled Item')) ?></td>
                  <td><span class="badge bg-light text-dark rounded-pill"><?= e($un['scan_type']) ?></span></td>
                  <td><span class="badge-status <?= strtolower(str_replace(' ', '-', $un['review_status'])) ?>"><?= e($un['review_status']) ?></span></td>
                  <td>
                    <a href="<?= base_url('unknown-products.php?action=review&id=' . (int)$un['id']) ?>" class="btn btn-sm btn-outline-primary py-1 px-2 rounded-2">Review</a>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Section 7: Recent Admin Activity Logs -->
  <div class="col-lg-6">
    <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden h-100">
      <div class="p-3 px-4 border-bottom d-flex justify-content-between align-items-center">
        <div class="d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-secondary fs-5">shield</span>
          <h4 class="h6 fw-bold mb-0">7. Recent Admin Activity</h4>
        </div>
        <?php if (can_manage_admins()): ?>
          <a href="<?= base_url('activity-logs.php') ?>" class="text-decoration-none small fw-semibold text-secondary">Full Audit Trail</a>
        <?php endif; ?>
      </div>
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
          <thead class="table-light">
            <tr>
              <th>Admin</th>
              <th>Action</th>
              <th>Description</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            <?php if (empty($recentLogs)): ?>
              <tr><td colspan="4" class="text-center py-4 text-muted">No activity logs recorded yet.</td></tr>
            <?php else: ?>
              <?php foreach ($recentLogs as $log): ?>
                <tr>
                  <td class="fw-bold"><?= e($log['admin_name']) ?></td>
                  <td><span class="badge bg-primary-subtle text-primary rounded-pill"><?= e($log['action']) ?></span></td>
                  <td class="text-muted text-truncate" style="max-width: 180px;"><?= e($log['description']) ?></td>
                  <td class="text-muted" style="font-size: 11.5px;"><?= format_date($log['created_at'], 'M d H:i') ?></td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<!-- Embedded Chart Data for charts.js -->
<script>
window.categoryChartData = {
  labels: <?= json_encode($chartCatLabels) ?>,
  counts: <?= json_encode($chartCatCounts) ?>,
  colors: <?= json_encode($chartCatColors) ?>
};
window.scansChartData = {
  labels: <?= json_encode($chartScansLabels) ?>,
  counts: <?= json_encode($chartScansCounts) ?>
};
window.expiryChartData = {
  safe: <?= $safeCount ?>,
  expiringSoon: <?= $expiringWithin7 ?>,
  expired: <?= $expiredProducts ?>,
  noExpiry: <?= $noExpiryProducts ?>
};
</script>

<?php 
$extraJs = '<script src="' . base_url('assets/js/charts.js') . '"></script>';
require_once __DIR__ . '/includes/footer.php'; 
?>
