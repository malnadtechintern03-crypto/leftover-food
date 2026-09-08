<?php
/**
 * ScanSmart Admin Activity Logs & Security Audit Trail
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin');

$db = Database::getConnection();

// Clear Logs (Super Admin only)
if (isset($_GET['clear_all']) && can_manage_admins()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } else {
        $db->query('TRUNCATE TABLE admin_activity_logs');
        log_admin_activity('Clear Activity Logs', 'Cleared administrative audit trail');
        set_flash('success', 'Admin activity logs have been reset.');
    }
    header('Location: ' . base_url('activity-logs.php'));
    exit;
}

$search = trim((string)($_GET['q'] ?? ''));
$actionFilter = trim((string)($_GET['action'] ?? ''));

$where = [];
$params = [];

if ($search !== '') {
    $where[] = "(admin_name LIKE ? OR description LIKE ? OR ip_address LIKE ?)";
    $like = "%{$search}%";
    $params = array_merge($params, [$like, $like, $like]);
}

if ($actionFilter !== '') {
    $where[] = "action = ?";
    $params[] = $actionFilter;
}

$whereSql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

$stmt = $db->prepare("
    SELECT * FROM admin_activity_logs
    {$whereSql}
    ORDER BY id DESC
    LIMIT 150
");
$stmt->execute($params);
$logs = $stmt->fetchAll();

$actionsList = $db->query("SELECT DISTINCT action FROM admin_activity_logs ORDER BY action ASC")->fetchAll(PDO::FETCH_COLUMN);

$pageTitle = 'Security Activity Logs';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Administrative Audit Trail & Activity Logs</h2>
    <p class="text-muted small mb-0">Record of authentication events, catalog changes, and administrative actions.</p>
  </div>
  <div class="d-flex gap-2">
    <?php if (!empty($logs)): ?>
      <a href="<?= base_url('activity-logs.php?clear_all=1&csrf_token=' . e(csrf_token())) ?>" class="btn btn-outline-danger rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1" onclick="return confirm('Clear all activity logs?');">
        <span class="material-symbols-rounded fs-6">delete_sweep</span>
        <span>Clear Logs</span>
      </a>
    <?php endif; ?>
  </div>
</div>

<!-- Filter Bar -->
<div class="card border-0 shadow-sm rounded-4 mb-4 bg-white p-3 p-md-4">
  <form method="GET" action="" class="row g-2 align-items-end">
    <div class="col-md-6">
      <label for="q" class="form-label small fw-bold text-muted">Search Audit Trail</label>
      <input type="text" name="q" id="q" value="<?= e($search) ?>" class="form-control bg-light" placeholder="Administrator name, action description, IP...">
    </div>

    <div class="col-6 col-md-4">
      <label for="action" class="form-label small fw-bold text-muted">Filter Action</label>
      <select name="action" id="action" class="form-select bg-light">
        <option value="">All Actions</option>
        <?php foreach ($actionsList as $act): ?>
          <option value="<?= e($act) ?>" <?= $actionFilter === $act ? 'selected' : '' ?>><?= e($act) ?></option>
        <?php endforeach; ?>
      </select>
    </div>

    <div class="col-6 col-md-2 d-flex gap-2">
      <button type="submit" class="btn btn-primary w-100 fw-semibold" style="background-color: #10B981; border-color: #10B981;">Filter</button>
      <?php if ($search !== '' || $actionFilter !== ''): ?>
        <a href="<?= base_url('activity-logs.php') ?>" class="btn btn-light border" title="Reset"><span class="material-symbols-rounded fs-6">close</span></a>
      <?php endif; ?>
    </div>
  </form>
</div>

<!-- Logs Table -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <tr>
          <th>Log ID</th>
          <th>Admin User</th>
          <th>Action Type</th>
          <th>Event Description</th>
          <th>Origin IP Address</th>
          <th>Date & Time</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($logs)): ?>
          <tr><td colspan="6" class="text-center py-5 text-muted">No activity logs recorded yet.</td></tr>
        <?php else: ?>
          <?php foreach ($logs as $log): ?>
            <tr>
              <td><code>#<?= $log['id'] ?></code></td>
              <td>
                <div class="fw-bold text-dark"><?= e($log['admin_name']) ?></div>
                <div class="text-muted small">Admin #<?= $log['admin_id'] ?? 'N/A' ?></div>
              </td>
              <td><span class="badge bg-primary-subtle text-primary rounded-pill px-2.5 py-1"><?= e($log['action']) ?></span></td>
              <td class="text-muted" style="max-width: 320px;"><?= e($log['description']) ?></td>
              <td><code><?= e($log['ip_address'] ?: '127.0.0.1') ?></code></td>
              <td class="text-muted"><?= format_date($log['created_at'], 'M d, Y H:i:s') ?></td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
