<?php
/**
 * ScanSmart Mobile Scan Telemetry & History
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// Export Scan History to CSV
if (isset($_GET['export']) && $_GET['export'] === 'csv') {
    $expStmt = $db->query("
        SELECT id, user_id, barcode, scan_type, product_found, product_name, scan_date, scan_time, scan_result
        FROM scan_history
        ORDER BY scan_date DESC, scan_time DESC
    ");
    $rows = $expStmt->fetchAll();
    $headers = ['Scan ID', 'User ID', 'Barcode', 'Scan Type', 'Found (1=Yes, 0=No)', 'Product Name', 'Scan Date', 'Scan Time', 'Scan Result Payload'];
    log_admin_activity('Export Scan History CSV', 'Exported mobile scan history to CSV (' . count($rows) . ' records)');
    export_to_csv('scansmart_scans_' . date('Ymd_His') . '.csv', $headers, $rows);
}

// Clear old scans (Super Admin only)
if (isset($_GET['clear_all']) && can_manage_admins()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } else {
        $db->query('TRUNCATE TABLE scan_history');
        log_admin_activity('Clear Scan History', 'Cleared mobile scan telemetry log');
        set_flash('success', 'All scan history logs have been cleared.');
    }
    header('Location: ' . base_url('scan-history.php'));
    exit;
}

// Filters & Query
$search = trim((string)($_GET['q'] ?? ''));
$scanType = trim((string)($_GET['type'] ?? ''));
$resultFilter = trim((string)($_GET['result'] ?? ''));
$startDate = trim((string)($_GET['start_date'] ?? ''));
$endDate = trim((string)($_GET['end_date'] ?? ''));

$where = [];
$params = [];

if ($search !== '') {
    $where[] = "(barcode LIKE ? OR product_name LIKE ? OR user_id LIKE ?)";
    $like = "%{$search}%";
    $params = array_merge($params, [$like, $like, $like]);
}

if ($scanType !== '') {
    $where[] = "scan_type = ?";
    $params[] = $scanType;
}

if ($resultFilter === 'found') {
    $where[] = "product_found = 1";
} elseif ($resultFilter === 'not_found') {
    $where[] = "product_found = 0";
}

if ($startDate !== '') {
    $where[] = "scan_date >= ?";
    $params[] = $startDate;
}

if ($endDate !== '') {
    $where[] = "scan_date <= ?";
    $params[] = $endDate;
}

$whereSql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

$stmt = $db->prepare("
    SELECT * FROM scan_history
    {$whereSql}
    ORDER BY scan_date DESC, scan_time DESC, id DESC
    LIMIT 100
");
$stmt->execute($params);
$scans = $stmt->fetchAll();

// Telemetry Stats
$totalScans = (int)$db->query("SELECT COUNT(*) FROM scan_history")->fetchColumn();
$foundScans = (int)$db->query("SELECT COUNT(*) FROM scan_history WHERE product_found = 1")->fetchColumn();
$notFoundScans = (int)$db->query("SELECT COUNT(*) FROM scan_history WHERE product_found = 0")->fetchColumn();
$successRate = $totalScans > 0 ? round(($foundScans / $totalScans) * 100, 1) : 100.0;

$pageTitle = 'Mobile Scan History';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Mobile Scan Telemetry & History</h2>
    <p class="text-muted small mb-0">Audit barcode, QR code, and OCR camera scans performed from the mobile app.</p>
  </div>
  <div class="d-flex gap-2">
    <a href="<?= base_url('scan-history.php?export=csv') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-5">download</span>
      <span>Export Scans CSV</span>
    </a>
    <?php if (can_manage_admins() && $totalScans > 0): ?>
      <a href="<?= base_url('scan-history.php?clear_all=1&csrf_token=' . e(csrf_token())) ?>" class="btn btn-outline-danger rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1" onclick="return confirm('Clear all recorded mobile scan logs?');">
        <span class="material-symbols-rounded fs-5">delete_sweep</span>
        <span>Clear Logs</span>
      </a>
    <?php endif; ?>
  </div>
</div>

<!-- Stats Row -->
<div class="row g-3 mb-4">
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #ECFEFF; color: #06B6D4;"><span class="material-symbols-rounded">qr_code_scanner</span></div>
      <div>
        <div class="card-stat-val"><?= number_format($totalScans) ?></div>
        <div class="card-stat-lbl">Total Scans</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #ECFDF5; color: #10B981;"><span class="material-symbols-rounded">check_circle</span></div>
      <div>
        <div class="card-stat-val text-success"><?= number_format($foundScans) ?></div>
        <div class="card-stat-lbl">Recognized</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FEF9C3; color: #CA8A04;"><span class="material-symbols-rounded">help_center</span></div>
      <div>
        <div class="card-stat-val" style="color: #CA8A04;"><?= number_format($notFoundScans) ?></div>
        <div class="card-stat-lbl">Unknown Barcodes</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #F5F3FF; color: #8B5CF6;"><span class="material-symbols-rounded">target</span></div>
      <div>
        <div class="card-stat-val text-primary"><?= $successRate ?>%</div>
        <div class="card-stat-lbl">Catalog Hit Rate</div>
      </div>
    </div>
  </div>
</div>

<!-- Filter Form -->
<div class="card border-0 shadow-sm rounded-4 mb-4 bg-white p-3 p-md-4">
  <form method="GET" action="" class="row g-2 align-items-end">
    <div class="col-md-4">
      <label for="q" class="form-label small fw-bold text-muted">Search Barcode or Name</label>
      <input type="text" name="q" id="q" value="<?= e($search) ?>" class="form-control bg-light" placeholder="Barcode, product title, user ID...">
    </div>

    <div class="col-6 col-md-2">
      <label for="type" class="form-label small fw-bold text-muted">Scan Type</label>
      <select name="type" id="type" class="form-select bg-light">
        <option value="">All Types</option>
        <option value="Barcode" <?= $scanType === 'Barcode' ? 'selected' : '' ?>>Barcode</option>
        <option value="QR Code" <?= $scanType === 'QR Code' ? 'selected' : '' ?>>QR Code</option>
        <option value="OCR" <?= $scanType === 'OCR' ? 'selected' : '' ?>>OCR Camera</option>
        <option value="Manual Entry" <?= $scanType === 'Manual Entry' ? 'selected' : '' ?>>Manual Entry</option>
      </select>
    </div>

    <div class="col-6 col-md-2">
      <label for="result" class="form-label small fw-bold text-muted">Result</label>
      <select name="result" id="result" class="form-select bg-light">
        <option value="">All Results</option>
        <option value="found" <?= $resultFilter === 'found' ? 'selected' : '' ?>>Recognized (Found)</option>
        <option value="not_found" <?= $resultFilter === 'not_found' ? 'selected' : '' ?>>Not in Catalog</option>
      </select>
    </div>

    <div class="col-6 col-md-2">
      <label for="start_date" class="form-label small fw-bold text-muted">Date From</label>
      <input type="date" name="start_date" id="start_date" class="form-control bg-light" value="<?= e($startDate) ?>">
    </div>

    <div class="col-6 col-md-2 d-flex gap-2">
      <button type="submit" class="btn btn-primary w-100 fw-semibold" style="background-color: #10B981; border-color: #10B981;">Filter</button>
      <?php if ($search !== '' || $scanType !== '' || $resultFilter !== '' || $startDate !== ''): ?>
        <a href="<?= base_url('scan-history.php') ?>" class="btn btn-light border" title="Reset"><span class="material-symbols-rounded fs-6">close</span></a>
      <?php endif; ?>
    </div>
  </form>
</div>

<!-- Scans Table -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <tr>
          <th>Scan ID</th>
          <th>Barcode / Payload</th>
          <th>Recognized Product</th>
          <th>User</th>
          <th>Scan Mode</th>
          <th>Catalog Status</th>
          <th>Date & Timestamp</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($scans)): ?>
          <tr><td colspan="7" class="text-center py-5 text-muted">No scan history records found matching query.</td></tr>
        <?php else: ?>
          <?php foreach ($scans as $s): ?>
            <tr>
              <td><code>#<?= $s['id'] ?></code></td>
              <td><span class="barcode-pill"><?= e($s['barcode'] ?: 'No Barcode') ?></span></td>
              <td class="fw-bold text-dark"><?= e($s['product_name'] ?: 'Uncataloged Item') ?></td>
              <td><code><?= e($s['user_id']) ?></code></td>
              <td><span class="badge bg-light text-dark rounded-pill border"><?= e($s['scan_type']) ?></span></td>
              <td>
                <?php if ((int)$s['product_found'] === 1): ?>
                  <span class="badge bg-success-subtle text-success rounded-pill d-inline-flex align-items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 13px;">check_circle</span>
                    <span>Found in Catalog</span>
                  </span>
                <?php else: ?>
                  <span class="badge bg-warning-subtle text-warning rounded-pill d-inline-flex align-items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 13px;">help_center</span>
                    <span>Unrecognized</span>
                  </span>
                <?php endif; ?>
              </td>
              <td class="text-muted"><?= format_date($s['scan_date']) ?> <?= substr($s['scan_time'], 0, 5) ?></td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
