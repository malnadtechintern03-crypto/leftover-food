<?php
/**
 * ScanSmart Expiration Management - Expiration Alerts Center
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// Quick Update of Expiry Date / Reminders via POST
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'quick_update_expiry') {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } elseif (!can_edit_products()) {
        set_flash('error', 'Permission denied.');
    } else {
        $prodId = trim($_POST['product_id'] ?? '');
        $newExpiry = trim($_POST['expiry_date'] ?? '');
        $reminderEnabled = isset($_POST['reminder_enabled']) ? 1 : 0;
        $reminderDays = (int)($_POST['reminder_days_before'] ?? 7);

        if ($prodId !== '') {
            $exp = $newExpiry !== '' ? $newExpiry : null;
            $expiryStatus = 'No Expiry Date';
            $reminderDate = null;

            if ($exp !== null) {
                $today = new DateTime('today');
                $expDt = new DateTime($exp);
                $diff = (int)$today->diff($expDt)->format('%r%a');
                if ($diff < 0) {
                    $expiryStatus = 'Expired';
                } elseif ($diff <= 7) {
                    $expiryStatus = 'Expiring Soon';
                } else {
                    $expiryStatus = 'Safe';
                }

                if ($reminderEnabled) {
                    $remDt = new DateTime($exp);
                    $remDt->modify("-{$reminderDays} days");
                    $reminderDate = $remDt->format('Y-m-d 09:00:00');
                }
            }

            $stmt = $db->prepare("
                UPDATE products SET
                    expiry_date = ?, expiry_status = ?, reminder_enabled = ?,
                    reminder_days_before = ?, reminder_date = ?
                WHERE id = ?
            ");
            $stmt->execute([$exp, $expiryStatus, $reminderEnabled, (string)$reminderDays, $reminderDate, $prodId]);

            // Sync product_reminders table
            if ($exp !== null && $reminderEnabled && $reminderDate !== null) {
                $notifId = abs(crc32($prodId));
                $db->prepare("
                    INSERT INTO product_reminders (user_id, product_id, reminder_date, days_before_expiry, notification_id, is_enabled)
                    VALUES ('default_user', ?, ?, ?, ?, 1)
                    ON DUPLICATE KEY UPDATE reminder_date = VALUES(reminder_date), days_before_expiry = VALUES(days_before_expiry), is_enabled = 1
                ")->execute([$prodId, $reminderDate, $reminderDays, $notifId]);
            } else {
                $db->prepare("UPDATE product_reminders SET is_enabled = 0 WHERE product_id = ?")->execute([$prodId]);
            }

            log_admin_activity('Update Expiry', "Updated expiry date to '{$exp}' for product #{$prodId}");
            set_flash('success', 'Expiration date and reminder schedule updated.');
        }
    }
    header('Location: ' . base_url('expiration-alerts.php?' . http_build_query($_GET)));
    exit;
}

// Handle Expiry CSV Export
if (isset($_GET['export']) && $_GET['export'] === 'csv') {
    $expStmt = $db->query("
        SELECT barcode, name, category, quantity, unit, storage_location, expiry_date,
               DATEDIFF(expiry_date, CURDATE()) as days_remaining, expiry_status, reminder_enabled
        FROM products
        WHERE status != 'Archived' AND expiry_date IS NOT NULL
        ORDER BY expiry_date ASC
    ");
    $rows = $expStmt->fetchAll();
    $headers = ['Barcode', 'Name', 'Category', 'Quantity', 'Unit', 'Location', 'Expiry Date', 'Days Remaining', 'Status', 'Reminder Active'];
    log_admin_activity('Export Expiry Report', 'Exported expiration report to CSV (' . count($rows) . ' records)');
    export_to_csv('scansmart_expiry_report_' . date('Ymd') . '.csv', $headers, $rows);
}

// Filter Logic
$filter = trim((string)($_GET['filter'] ?? 'all'));
$categoryFilter = trim((string)($_GET['category'] ?? ''));
$startDate = trim((string)($_GET['start_date'] ?? ''));
$endDate = trim((string)($_GET['end_date'] ?? ''));

$where = ["status != 'Archived'"];
$params = [];

switch ($filter) {
    case 'expired':
        $where[] = "expiry_date IS NOT NULL AND expiry_date < CURDATE()";
        break;
    case 'expiring_today':
        $where[] = "expiry_date IS NOT NULL AND expiry_date = CURDATE()";
        break;
    case 'expiring_soon':
        $where[] = "expiry_date IS NOT NULL AND expiry_date >= CURDATE() AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)";
        break;
    case 'expiring_30':
        $where[] = "expiry_date IS NOT NULL AND expiry_date > DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)";
        break;
    case 'no_expiry':
        $where[] = "expiry_date IS NULL";
        break;
    case 'safe':
        $where[] = "expiry_date IS NOT NULL AND expiry_date > DATE_ADD(CURDATE(), INTERVAL 7 DAY)";
        break;
}

if ($categoryFilter !== '') {
    $where[] = "category = ?";
    $params[] = $categoryFilter;
}

if ($startDate !== '') {
    $where[] = "expiry_date >= ?";
    $params[] = $startDate;
}

if ($endDate !== '') {
    $where[] = "expiry_date <= ?";
    $params[] = $endDate;
}

$whereSql = implode(' AND ', $where);

$stmt = $db->prepare("
    SELECT id, name, brand, barcode, category, quantity, unit, storage_location,
           manufacturing_date, expiry_date, reminder_date, reminder_enabled, reminder_days_before,
           expiry_status, status, DATEDIFF(expiry_date, CURDATE()) AS days_remaining
    FROM products
    WHERE {$whereSql}
    ORDER BY expiry_date IS NULL ASC, expiry_date ASC
");
$stmt->execute($params);
$items = $stmt->fetchAll();

// Counts for filter pills
$countExpired = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date IS NOT NULL AND expiry_date < CURDATE()")->fetchColumn();
$countToday = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date IS NOT NULL AND expiry_date = CURDATE()")->fetchColumn();
$countSoon = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date IS NOT NULL AND expiry_date >= CURDATE() AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)")->fetchColumn();
$count30 = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date IS NOT NULL AND expiry_date > DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)")->fetchColumn();
$countNoExp = (int)$db->query("SELECT COUNT(*) FROM products WHERE status != 'Archived' AND expiry_date IS NULL")->fetchColumn();

$categories = $db->query("SELECT name FROM categories WHERE status = 'active' ORDER BY name ASC")->fetchAll(PDO::FETCH_COLUMN);

$pageTitle = 'Expiration Alerts & Telemetry';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Expiration Alerts & Freshness Telemetry</h2>
    <p class="text-muted small mb-0">Track upcoming expiration dates, edit reminders, and avoid inventory waste.</p>
  </div>
  <div class="d-flex gap-2">
    <a href="<?= base_url('expiration-alerts.php?export=csv') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-5">download</span>
      <span>Export Expiry Report</span>
    </a>
    <a href="<?= base_url('reminders.php') ?>" class="btn btn-primary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1" style="background-color: #10B981; border-color: #10B981;">
      <span class="material-symbols-rounded fs-5">alarm</span>
      <span>Reminder Schedules</span>
    </a>
  </div>
</div>

<!-- Quick Expiration Filter Pills -->
<div class="d-flex flex-wrap gap-2 mb-4">
  <a href="<?= base_url('expiration-alerts.php?filter=all') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $filter === 'all' ? 'btn-dark' : 'btn-light border text-dark' ?>">
    All Items
  </a>
  <a href="<?= base_url('expiration-alerts.php?filter=expired') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $filter === 'expired' ? 'btn-danger' : 'btn-light border text-danger' ?>">
    Expired <span class="badge bg-danger rounded-pill ms-1 text-white"><?= $countExpired ?></span>
  </a>
  <a href="<?= base_url('expiration-alerts.php?filter=expiring_today') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $filter === 'expiring_today' ? 'btn-danger' : 'btn-light border text-danger' ?>">
    Expiring Today <span class="badge bg-danger rounded-pill ms-1 text-white"><?= $countToday ?></span>
  </a>
  <a href="<?= base_url('expiration-alerts.php?filter=expiring_soon') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $filter === 'expiring_soon' ? 'btn-warning text-dark' : 'btn-light border text-warning' ?>">
    &le; 7 Days <span class="badge bg-warning text-dark rounded-pill ms-1"><?= $countSoon ?></span>
  </a>
  <a href="<?= base_url('expiration-alerts.php?filter=expiring_30') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $filter === 'expiring_30' ? 'btn-secondary text-white' : 'btn-light border text-secondary' ?>">
    &le; 30 Days <span class="badge bg-secondary rounded-pill ms-1 text-white"><?= $count30 ?></span>
  </a>
  <a href="<?= base_url('expiration-alerts.php?filter=no_expiry') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $filter === 'no_expiry' ? 'btn-secondary text-white' : 'btn-light border text-muted' ?>">
    No Expiry Date <span class="badge bg-light text-dark rounded-pill ms-1 border"><?= $countNoExp ?></span>
  </a>
</div>

<!-- Date & Category Filter Bar -->
<div class="card border-0 shadow-sm rounded-4 mb-4 bg-white p-3 p-md-4">
  <form method="GET" action="" class="row g-2 align-items-end">
    <input type="hidden" name="filter" value="<?= e($filter) ?>">

    <div class="col-6 col-md-3">
      <label for="category" class="form-label small fw-bold text-muted">Category</label>
      <select name="category" id="category" class="form-select bg-light">
        <option value="">All Categories</option>
        <?php foreach ($categories as $cat): ?>
          <option value="<?= e($cat) ?>" <?= $categoryFilter === $cat ? 'selected' : '' ?>><?= e($cat) ?></option>
        <?php endforeach; ?>
      </select>
    </div>

    <div class="col-6 col-md-3">
      <label for="start_date" class="form-label small fw-bold text-muted">From Expiry Date</label>
      <input type="date" name="start_date" id="start_date" class="form-control bg-light" value="<?= e($startDate) ?>">
    </div>

    <div class="col-6 col-md-3">
      <label for="end_date" class="form-label small fw-bold text-muted">To Expiry Date</label>
      <input type="date" name="end_date" id="end_date" class="form-control bg-light" value="<?= e($endDate) ?>">
    </div>

    <div class="col-6 col-md-3 d-flex gap-2">
      <button type="submit" class="btn btn-primary w-100 fw-semibold" style="background-color: #10B981; border-color: #10B981;">Filter Dates</button>
      <a href="<?= base_url('expiration-alerts.php?filter=' . urlencode($filter)) ?>" class="btn btn-light border" title="Reset"><span class="material-symbols-rounded fs-6">close</span></a>
    </div>
  </form>
</div>

<!-- Table of Products -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <tr>
          <th>Product Name & Brand</th>
          <th>Barcode</th>
          <th>Category</th>
          <th>Stock</th>
          <th>Location</th>
          <th>Expiry Date</th>
          <th>Status / Days Left</th>
          <th>Reminder Scheduled</th>
          <th width="110" class="text-end">Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($items)): ?>
          <tr>
            <td colspan="9" class="text-center py-5 text-muted">
              <span class="material-symbols-rounded fs-1 d-block mb-1">check_circle</span>
              <div class="fw-bold">No items found matching the selected expiration filter.</div>
            </td>
          </tr>
        <?php else: ?>
          <?php foreach ($items as $item): 
            $days = $item['days_remaining'] !== null ? (int)$item['days_remaining'] : null;
          ?>
            <tr>
              <td>
                <div class="fw-bold text-dark"><?= e($item['name']) ?></div>
                <div class="text-muted small"><?= e($item['brand'] ?: 'Generic') ?></div>
              </td>
              <td><?= !empty($item['barcode']) ? '<span class="barcode-pill">' . e($item['barcode']) . '</span>' : '<span class="text-muted">—</span>' ?></td>
              <td><span class="badge bg-light text-dark rounded-pill border"><?= e($item['category']) ?></span></td>
              <td><?= (float)$item['quantity'] ?> <?= e($item['unit']) ?></td>
              <td><span class="badge bg-secondary-subtle text-secondary rounded-pill"><?= e(ucfirst($item['storage_location'] ?? 'pantry')) ?></span></td>
              <td class="fw-bold">
                <?= format_date($item['expiry_date']) ?>
              </td>
              <td>
                <?php if ($item['expiry_date'] === null): ?>
                  <span class="badge-status no-expiry">No Expiry Date</span>
                <?php elseif ($days < 0): ?>
                  <span class="badge-status expired">Expired (<?= abs($days) ?>d overdue)</span>
                <?php elseif ($days === 0): ?>
                  <span class="badge-status expired">Expires Today!</span>
                <?php elseif ($days <= 7): ?>
                  <span class="badge-status expiring-soon"><?= $days ?> days left</span>
                <?php else: ?>
                  <span class="badge-status safe">Safe (<?= $days ?>d)</span>
                <?php endif; ?>
              </td>
              <td>
                <?php if ((int)$item['reminder_enabled'] === 1 && !empty($item['reminder_date'])): ?>
                  <span class="badge bg-primary-subtle text-primary rounded-pill d-inline-flex align-items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 13px;">alarm</span>
                    <span><?= format_date($item['reminder_date'], 'M d') ?> (<?= e($item['reminder_days_before']) ?>d prior)</span>
                  </span>
                <?php else: ?>
                  <span class="text-muted small">Disabled</span>
                <?php endif; ?>
              </td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <!-- Quick Edit Expiry Modal Trigger -->
                  <button type="button" class="btn btn-sm btn-light border py-1 px-2 rounded-2" data-bs-toggle="modal" data-bs-target="#modalQuickExpiry<?= md5($item['id']) ?>" title="Quick Adjust Expiry">
                    <span class="material-symbols-rounded" style="font-size: 16px;">edit_calendar</span>
                  </button>
                  <a href="<?= base_url('product-view.php?id=' . urlencode($item['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="View Details">
                    <span class="material-symbols-rounded" style="font-size: 16px;">visibility</span>
                  </a>
                </div>
              </td>
            </tr>

            <!-- Quick Modal for Adjusting Expiration Date & Reminders -->
            <div class="modal fade" id="modalQuickExpiry<?= md5($item['id']) ?>" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content rounded-4 border-0 shadow">
                  <div class="modal-header border-bottom">
                    <h5 class="modal-title fw-bold">Adjust Expiration: <?= e($item['name']) ?></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                  </div>
                  <form method="POST" action="">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="quick_update_expiry">
                    <input type="hidden" name="product_id" value="<?= e($item['id']) ?>">

                    <div class="modal-body p-4">
                      <div class="mb-3">
                        <label class="form-label small fw-bold">Expiration Date</label>
                        <input type="date" name="expiry_date" class="form-control" value="<?= e($item['expiry_date'] ?? '') ?>">
                        <div class="form-text" style="font-size: 11px;">Leave blank if item does not expire.</div>
                      </div>

                      <div class="form-check form-switch mb-3">
                        <input class="form-check-input" type="checkbox" role="switch" name="reminder_enabled" id="rem_sw_<?= md5($item['id']) ?>" <?= (int)$item['reminder_enabled'] === 1 ? 'checked' : '' ?>>
                        <label class="form-check-label small fw-bold" for="rem_sw_<?= md5($item['id']) ?>">Enable Expiry Notification Reminder</label>
                      </div>

                      <div class="mb-0">
                        <label class="form-label small fw-bold">Notify Days Before</label>
                        <select name="reminder_days_before" class="form-select">
                          <option value="1" <?= $item['reminder_days_before'] == '1' ? 'selected' : '' ?>>1 Day Before</option>
                          <option value="3" <?= $item['reminder_days_before'] == '3' ? 'selected' : '' ?>>3 Days Before</option>
                          <option value="7" <?= $item['reminder_days_before'] == '7' ? 'selected' : '' ?>>7 Days Before</option>
                          <option value="14" <?= $item['reminder_days_before'] == '14' ? 'selected' : '' ?>>14 Days Before</option>
                          <option value="30" <?= $item['reminder_days_before'] == '30' ? 'selected' : '' ?>>30 Days Before</option>
                        </select>
                      </div>
                    </div>
                    <div class="modal-footer border-top">
                      <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">Cancel</button>
                      <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Save Expiry Schedule</button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
