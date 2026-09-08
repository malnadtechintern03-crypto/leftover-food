<?php
/**
 * ScanSmart Reminder Management - Scheduled Expiry Alerts
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// Toggle reminder status (Enable/Disable)
if (isset($_GET['toggle']) && can_edit_products()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } else {
        $remId = (int)$_GET['toggle'];
        $stmt = $db->prepare('SELECT id, is_enabled FROM product_reminders WHERE id = ? LIMIT 1');
        $stmt->execute([$remId]);
        $r = $stmt->fetch();
        if ($r) {
            $newStatus = (int)$r['is_enabled'] === 1 ? 0 : 1;
            $db->prepare('UPDATE product_reminders SET is_enabled = ? WHERE id = ?')->execute([$newStatus, $remId]);
            set_flash('success', 'Reminder status toggled successfully.');
        }
    }
    header('Location: ' . base_url('reminders.php'));
    exit;
}

// Delete reminder
if (isset($_GET['delete']) && can_delete_products()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } else {
        $remId = (int)$_GET['delete'];
        $db->prepare('DELETE FROM product_reminders WHERE id = ?')->execute([$remId]);
        set_flash('success', 'Reminder schedule deleted.');
    }
    header('Location: ' . base_url('reminders.php'));
    exit;
}

// Edit reminder form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'edit_reminder') {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } elseif (!can_edit_products()) {
        set_flash('error', 'Permission denied.');
    } else {
        $remId = (int)($_POST['reminder_id'] ?? 0);
        $remDate = trim($_POST['reminder_date'] ?? '');
        $daysBefore = (int)($_POST['days_before_expiry'] ?? 7);
        $isEnabled = isset($_POST['is_enabled']) ? 1 : 0;

        if ($remId > 0 && $remDate !== '') {
            $stmt = $db->prepare('UPDATE product_reminders SET reminder_date = ?, days_before_expiry = ?, is_enabled = ? WHERE id = ?');
            $stmt->execute([$remDate, $daysBefore, $isEnabled, $remId]);
            log_admin_activity('Update Reminder', "Modified reminder schedule #{$remId}");
            set_flash('success', 'Reminder schedule updated.');
        }
    }
    header('Location: ' . base_url('reminders.php'));
    exit;
}

// Filters
$statusFilter = trim((string)($_GET['status'] ?? 'all'));
$where = [];
$params = [];

if ($statusFilter === 'pending') {
    $where[] = "r.is_sent = 0 AND r.is_enabled = 1";
} elseif ($statusFilter === 'sent') {
    $where[] = "r.is_sent = 1";
} elseif ($statusFilter === 'disabled') {
    $where[] = "r.is_enabled = 0";
}

$whereSql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

$stmt = $db->prepare("
    SELECT r.*, p.name AS product_name, p.brand, p.barcode, p.expiry_date, p.category, p.storage_location
    FROM product_reminders r
    JOIN products p ON p.id = r.product_id
    {$whereSql}
    ORDER BY r.reminder_date ASC
");
$stmt->execute($params);
$reminders = $stmt->fetchAll();

// Counts
$totalRem = (int)$db->query('SELECT COUNT(*) FROM product_reminders')->fetchColumn();
$pendingRem = (int)$db->query('SELECT COUNT(*) FROM product_reminders WHERE is_sent = 0 AND is_enabled = 1')->fetchColumn();
$sentRem = (int)$db->query('SELECT COUNT(*) FROM product_reminders WHERE is_sent = 1')->fetchColumn();
$disabledRem = (int)$db->query('SELECT COUNT(*) FROM product_reminders WHERE is_enabled = 0')->fetchColumn();

$pageTitle = 'Expiration Reminders';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Product Expiration Reminders</h2>
    <p class="text-muted small mb-0">Manage scheduled push notification alerts triggered before items expire.</p>
  </div>
  <a href="<?= base_url('expiration-alerts.php') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
    <span class="material-symbols-rounded fs-6">arrow_back</span>
    <span>View Expiry Alerts</span>
  </a>
</div>

<!-- Summary Status Cards -->
<div class="row g-3 mb-4">
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #EFF6FF; color: #3B82F6;"><span class="material-symbols-rounded">alarm</span></div>
      <div>
        <div class="card-stat-val"><?= $totalRem ?></div>
        <div class="card-stat-lbl">Total Scheduled</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #FFFBEB; color: #F59E0B;"><span class="material-symbols-rounded">schedule</span></div>
      <div>
        <div class="card-stat-val text-warning"><?= $pendingRem ?></div>
        <div class="card-stat-lbl">Pending Trigger</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #ECFDF5; color: #10B981;"><span class="material-symbols-rounded">done_all</span></div>
      <div>
        <div class="card-stat-val text-success"><?= $sentRem ?></div>
        <div class="card-stat-lbl">Alerts Sent</div>
      </div>
    </div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card-stat-modern">
      <div class="card-stat-icon" style="background: #F1F5F9; color: #64748B;"><span class="material-symbols-rounded">alarm_off</span></div>
      <div>
        <div class="card-stat-val text-muted"><?= $disabledRem ?></div>
        <div class="card-stat-lbl">Disabled</div>
      </div>
    </div>
  </div>
</div>

<!-- Filter Tabs -->
<div class="d-flex flex-wrap gap-2 mb-4">
  <a href="<?= base_url('reminders.php?status=all') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'all' ? 'btn-dark' : 'btn-light border text-dark' ?>">All</a>
  <a href="<?= base_url('reminders.php?status=pending') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'pending' ? 'btn-warning text-dark' : 'btn-light border text-warning' ?>">Pending (<?= $pendingRem ?>)</a>
  <a href="<?= base_url('reminders.php?status=sent') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'sent' ? 'btn-success text-white' : 'btn-light border text-success' ?>">Sent (<?= $sentRem ?>)</a>
  <a href="<?= base_url('reminders.php?status=disabled') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'disabled' ? 'btn-secondary text-white' : 'btn-light border text-muted' ?>">Disabled (<?= $disabledRem ?>)</a>
</div>

<!-- Reminders Table -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <tr>
          <th>Product</th>
          <th>Barcode</th>
          <th>Product Expiry</th>
          <th>Reminder Date</th>
          <th>Advance Notice</th>
          <th>Notification Status</th>
          <th>Schedule Active</th>
          <th width="120" class="text-end">Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($reminders)): ?>
          <tr><td colspan="8" class="text-center py-5 text-muted">No reminder records found.</td></tr>
        <?php else: ?>
          <?php foreach ($reminders as $rem): ?>
            <tr>
              <td>
                <div class="fw-bold text-dark"><?= e($rem['product_name']) ?></div>
                <div class="text-muted small"><?= e($rem['brand'] ?: 'Generic') ?> &bull; <?= e($rem['category']) ?></div>
              </td>
              <td><?= !empty($rem['barcode']) ? '<span class="barcode-pill">' . e($rem['barcode']) . '</span>' : '<span class="text-muted">—</span>' ?></td>
              <td class="fw-semibold text-danger"><?= format_date($rem['expiry_date']) ?></td>
              <td class="fw-bold text-primary"><?= format_date($rem['reminder_date'], 'M d, Y H:i') ?></td>
              <td><span class="badge bg-light text-dark border rounded-pill"><?= (int)$rem['days_before_expiry'] ?> days prior</span></td>
              <td>
                <?php if ((int)$rem['is_sent'] === 1): ?>
                  <span class="badge bg-success-subtle text-success rounded-pill d-inline-flex align-items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 13px;">check_circle</span>
                    <span>Delivered (<?= format_date($rem['last_sent_at'], 'M d') ?>)</span>
                  </span>
                <?php else: ?>
                  <span class="badge bg-warning-subtle text-warning rounded-pill d-inline-flex align-items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 13px;">schedule</span>
                    <span>Pending</span>
                  </span>
                <?php endif; ?>
              </td>
              <td>
                <?php if ((int)$rem['is_enabled'] === 1): ?>
                  <span class="badge-status active">Enabled</span>
                <?php else: ?>
                  <span class="badge-status inactive">Disabled</span>
                <?php endif; ?>
              </td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <?php if (can_edit_products()): ?>
                    <a href="<?= base_url('reminders.php?toggle=' . (int)$rem['id'] . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="<?= (int)$rem['is_enabled'] === 1 ? 'Disable' : 'Enable' ?>">
                      <span class="material-symbols-rounded" style="font-size: 16px;"><?= (int)$rem['is_enabled'] === 1 ? 'pause' : 'play_arrow' ?></span>
                    </a>
                    <button type="button" class="btn btn-sm btn-light border py-1 px-2 rounded-2" data-bs-toggle="modal" data-bs-target="#modalEditRem<?= $rem['id'] ?>" title="Edit Schedule">
                      <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                    </button>
                  <?php endif; ?>
                  <?php if (can_delete_products()): ?>
                    <a href="<?= base_url('reminders.php?delete=' . (int)$rem['id'] . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-sm btn-light border text-danger py-1 px-2 rounded-2" title="Delete Reminder" onclick="return confirm('Delete this reminder?');">
                      <span class="material-symbols-rounded" style="font-size: 16px;">delete</span>
                    </a>
                  <?php endif; ?>
                </div>
              </td>
            </tr>

            <!-- Modal Edit Reminder -->
            <div class="modal fade" id="modalEditRem<?= $rem['id'] ?>" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content rounded-4 border-0 shadow">
                  <div class="modal-header border-bottom">
                    <h5 class="modal-title fw-bold">Edit Reminder: <?= e($rem['product_name']) ?></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                  </div>
                  <form method="POST" action="">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="edit_reminder">
                    <input type="hidden" name="reminder_id" value="<?= $rem['id'] ?>">

                    <div class="modal-body p-4">
                      <div class="mb-3">
                        <label class="form-label small fw-bold">Notification Date & Time</label>
                        <input type="datetime-local" name="reminder_date" class="form-control" value="<?= date('Y-m-d\TH:i', strtotime($rem['reminder_date'])) ?>" required>
                      </div>

                      <div class="mb-3">
                        <label class="form-label small fw-bold">Advance Days</label>
                        <select name="days_before_expiry" class="form-select">
                          <option value="1" <?= $rem['days_before_expiry'] == 1 ? 'selected' : '' ?>>1 Day Before</option>
                          <option value="3" <?= $rem['days_before_expiry'] == 3 ? 'selected' : '' ?>>3 Days Before</option>
                          <option value="7" <?= $rem['days_before_expiry'] == 7 ? 'selected' : '' ?>>7 Days Before</option>
                          <option value="14" <?= $rem['days_before_expiry'] == 14 ? 'selected' : '' ?>>14 Days Before</option>
                          <option value="30" <?= $rem['days_before_expiry'] == 30 ? 'selected' : '' ?>>30 Days Before</option>
                        </select>
                      </div>

                      <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" role="switch" name="is_enabled" id="sw_en_<?= $rem['id'] ?>" <?= (int)$rem['is_enabled'] === 1 ? 'checked' : '' ?>>
                        <label class="form-check-label small fw-bold" for="sw_en_<?= $rem['id'] ?>">Active Notification Schedule</label>
                      </div>
                    </div>
                    <div class="modal-footer border-top">
                      <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">Cancel</button>
                      <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Save Changes</button>
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
